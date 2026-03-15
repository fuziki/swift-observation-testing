import Clocks
import Combine
import Foundation

/// Records changes in the value of the specified expression along with virtual time.
///
/// You do not create `TestObserver` directly; instead, call one of the `observe` overloads
/// on a ``TestTimeline``: ``TestTimeline/observe(_:)`` for `@Observable` expressions or
/// `Publisher` values, or ``TestTimeline/observe(_:_:)`` for `ObservableObject` instances.
///
/// After running the simulation with ``TestTimeline/advance(by:)``, inspect
/// ``events`` (or ``distinctEvents`` for `Equatable` values, or ``eventTimes``
/// for `Void` publishers) to assert the expected change history.
///
/// ```swift
/// let title = timeline.observe(vm.title)
/// await timeline.advance(by: .seconds(5))
///
/// #expect(title.events == [
///     .next(.zero,       "A"),
///     .next(.seconds(1), "B"),
/// ])
/// ```
@MainActor
public final class TestObserver<Value> {
    /// All events recorded during the simulation, in chronological order.
    ///
    /// Each element is a ``Recorded`` value containing the virtual time at which
    /// the change was detected and the new value of the observed expression.
    ///
    /// For `@Observable` objects and `ObservableObject` instances, the first event
    /// is always recorded at `.zero` and represents the initial value captured before
    /// the simulation starts. Publisher-based observers do not produce an initial event.
    public internal(set) var events: [Recorded<Value>] = []

    let timeline: TestTimeline
    nonisolated(unsafe) var expression: (() -> Value)?
    var cancellable: AnyCancellable?

    init(timeline: TestTimeline) {
        self.timeline = timeline
    }
}
