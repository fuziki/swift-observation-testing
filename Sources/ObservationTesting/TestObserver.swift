import Foundation
import Clocks
import Observation

/// Records changes in the value of the specified expression along with virtual time.
@MainActor
public final class TestObserver<Value> {
    /// History of recorded events
    public private(set) var events: [Recorded<Value>] = []

    private let timeline: TestTimeline
    private nonisolated(unsafe) let expression: () -> Value

    internal init(
        timeline: TestTimeline,
        expression: @escaping () -> Value
    ) {
        self.timeline = timeline
        self.expression = expression

        // Record the initial value at time zero
        events.append(.next(.zero, expression()))
        startObserving()
    }

    private func startObserving() {
        @Sendable func observeNext() {
            withObservationTracking {
                _ = expression()
            } onChange: { [weak self] in
                Task { @MainActor in
                    guard let self else { return }

                    let duration = self.timeline.startInstant.duration(to: self.timeline.clock.now)
                    await Task.yield()
                    self.events.append(.next(duration, self.expression()))

                    self.startObserving()
                }
            }
        }
        observeNext()
    }
}
