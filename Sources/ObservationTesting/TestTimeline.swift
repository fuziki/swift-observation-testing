import Foundation
import Clocks
import Combine

/// Manages virtual time and controls action execution (scenarios) at specified times.
@MainActor
public final class TestTimeline {
    public let clock = TestClock<Duration>()
    public let startInstant: TestClock<Duration>.Instant

    /// Type-erased Clock for injection into production code
    public var anyClock: AnyClock<Duration> { AnyClock(clock) }

    private var scheduledActions: [(time: Duration, action: @MainActor () async -> Void)] = []

    public init() {
        startInstant = clock.now
    }

    /// Registers an observable expression and creates a TestObserver
    public func observe<Value>(
        _ expression: @autoclosure @escaping @MainActor () -> Value
    ) -> TestObserver<Value> {
        TestObserver(timeline: self, expression: expression)
    }

    /// Registers a Publisher and creates a TestObserver that records emitted values
    public func observe<P: Publisher>(
        _ publisher: P
    ) -> TestObserver<P.Output> where P.Failure == Never {
        TestObserver(timeline: self, publisher: publisher)
    }

    /// Schedules an action at an absolute time measured from test start (0 seconds)
    public func schedule(at time: Duration, action: @escaping @MainActor () async -> Void) {
        scheduledActions.append((time, action))
    }

    /// Advances virtual time by the given duration and executes scheduled scenarios in time order
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
