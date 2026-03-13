import Clocks
import Combine
import Foundation

/// Manages virtual time and controls action execution (scenarios) at specified times.
///
/// `TestTimeline` is the entry point for timeline-based testing. It owns a `TestClock`
/// that you advance explicitly, letting you control when scheduled actions run and when
/// observed values are captured.
///
/// ## Overview
///
/// A typical test follows four steps:
///
/// 1. Create a `TestTimeline` and inject ``anyClock`` into the system-under-test.
/// 2. Call one of the three `observe` overloads to start recording values:
///    ``observe(_:)`` for `@Observable` expressions, ``observe(_:_:)`` for
///    `ObservableObject` instances, or ``observe(_:)`` for `Publisher` values.
/// 3. Call ``schedule(at:action:)`` for each action you want to fire at a specific virtual time.
/// 4. Call ``advance(by:)`` to run the simulation, then assert on the recorded ``TestObserver/events``.
///
/// ```swift
/// @Test @MainActor
/// func example() async {
///     let timeline = TestTimeline()
///     let vm = ViewModel(clock: timeline.anyClock)
///
///     let title = timeline.observe(vm.title)
///
///     timeline.schedule(at: .seconds(1)) { await vm.onTap() }
///
///     await timeline.advance(by: .seconds(5))
///
///     #expect(title.events == [
///         .next(.zero,       "A"),
///         .next(.seconds(1), "B"),
///         .next(.seconds(2), "C"),
///     ])
/// }
/// ```
@MainActor
public final class TestTimeline {
    /// The underlying test clock that drives virtual time.
    ///
    /// You can use this clock directly when you need fine-grained control over time
    /// advancement. In most cases, prefer ``advance(by:)`` which handles task
    /// scheduling automatically.
    public let clock = TestClock<Duration>()

    /// The instant at which the timeline was created, used as the origin (time zero).
    ///
    /// Recorded event times are measured as the ``Clocks/TestClock/Instant/duration(to:)``
    /// from this instant to the clock's current time when the value was captured.
    public let startInstant: TestClock<Duration>.Instant

    /// A type-erased clock suitable for injection into production code.
    ///
    /// Pass this value to any component that accepts an `AnyClock<Duration>` so that
    /// the component's internal `sleep` calls are controlled by this timeline's virtual clock.
    ///
    /// ```swift
    /// let timeline = TestTimeline()
    /// let vm = ViewModel(clock: timeline.anyClock)
    /// ```
    public var anyClock: AnyClock<Duration> {
        AnyClock(clock)
    }

    private var scheduledActions: [(time: Duration, action: @MainActor () async -> Void)] = []

    /// Creates a new timeline, setting the virtual clock origin to the current instant.
    public init() {
        startInstant = clock.now
    }

    /// Starts observing an `@Observable` expression and returns a ``TestObserver``.
    ///
    /// The expression is evaluated immediately to record the initial value at time zero,
    /// then re-evaluated whenever any `@Observable` property it accesses changes.
    ///
    /// - Parameter expression: An autoclosure that reads one or more `@Observable` properties.
    /// - Returns: A ``TestObserver`` that accumulates ``Recorded`` events over time.
    ///
    /// ```swift
    /// let title = timeline.observe(vm.title)
    /// ```
    public func observe<Value>(
        _ expression: @autoclosure @escaping @MainActor () -> Value
    ) -> TestObserver<Value> {
        TestObserver(timeline: self, expression: expression)
    }

    /// Starts observing a Combine `Publisher` and returns a ``TestObserver``.
    ///
    /// Each value emitted by the publisher is recorded with the virtual time at which
    /// it was received. Unlike the `@Observable` overload, no initial event is recorded
    /// before the publisher emits.
    ///
    /// - Parameter publisher: A publisher whose `Failure` type is `Never`.
    /// - Returns: A ``TestObserver`` that accumulates ``Recorded`` events over time.
    ///
    /// - Note: The subscription is held for the lifetime of the returned `TestObserver`.
    public func observe<P: Publisher>(
        _ publisher: P
    ) -> TestObserver<P.Output> where P.Failure == Never {
        TestObserver(timeline: self, publisher: publisher)
    }

    /// Starts observing an expression on an `ObservableObject` and returns a ``TestObserver``.
    ///
    /// The expression is evaluated immediately to capture the initial value at time zero.
    /// It is then re-evaluated after every `objectWillChange` notification fired by `object`.
    ///
    /// - Parameters:
    ///   - object: The `ObservableObject` whose changes drive re-evaluation.
    ///   - expression: An autoclosure that derives a value from `object`.
    /// - Returns: A ``TestObserver`` that accumulates ``Recorded`` events over time.
    ///
    /// ```swift
    /// let title = timeline.observe(vm, vm.title)
    /// ```
    public func observe<Value>(
        _ object: some ObservableObject,
        _ expression: @autoclosure @escaping () -> Value
    ) -> TestObserver<Value> {
        TestObserver(timeline: self, object: object, expression: expression)
    }

    /// Schedules an action to execute at a specific virtual time measured from time zero.
    ///
    /// Actions are executed when ``advance(by:)`` advances virtual time past the
    /// specified instant. Multiple actions at the same time are executed in
    /// registration order.
    ///
    /// - Parameters:
    ///   - time: The absolute virtual time, measured from test start, at which to fire `action`.
    ///   - action: The async closure to execute at `time`.
    ///
    /// ```swift
    /// timeline.schedule(at: .seconds(1)) { await vm.onTap() }
    /// timeline.schedule(at: .seconds(3)) { await vm.onReset() }
    /// ```
    public func schedule(at time: Duration, action: @escaping @MainActor () async -> Void) {
        scheduledActions.append((time, action))
    }

    /// Advances virtual time by the given duration and executes all pending scheduled actions.
    ///
    /// Call this method after registering observers and scheduling actions. It:
    ///
    /// 1. Sorts all pending actions by their scheduled time.
    /// 2. Creates tasks that sleep until their target instant, then call the action.
    /// 3. Yields twice so those tasks reliably reach their `sleep` calls.
    /// 4. Advances the virtual clock, waking tasks in chronological order.
    /// 5. Yields twice more so `@Observable` change callbacks propagate and
    ///    the resulting values are written to each ``TestObserver/events`` array.
    ///
    /// - Parameter duration: How far to advance the virtual clock from its current position.
    ///
    /// - Important: This method must be called from `@MainActor`. Mark your test function
    ///   with `@MainActor` or use `await MainActor.run { ... }`.
    public func advance(by duration: Duration) async {
        // Sort scheduled actions by absolute time ascending and register with TestClock
        let sorted = scheduledActions.sorted { $0.time < $1.time }
        for (time, action) in sorted {
            let targetInstant = startInstant.advanced(by: time)
            Task { @MainActor in
                try? await clock.sleep(until: targetInstant)
                await action()
            }
        }
        scheduledActions.removeAll()

        // Wait for registered Tasks to reliably reach clock.sleep
        await Task.yield()
        await Task.yield()

        // Advance virtual time (Tasks automatically fire and resume in scheduled order)
        await clock.advance(by: duration)

        // Wait for Observation's async update to complete and be written to TestObserver's events
        await Task.yield()
        await Task.yield()
    }
}
