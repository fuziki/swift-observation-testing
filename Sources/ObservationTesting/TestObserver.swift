import Foundation
import Clocks
import Observation
import Combine

/// Records changes in the value of the specified expression along with virtual time.
@MainActor
public final class TestObserver<Value> {
    /// History of recorded events
    public private(set) var events: [Recorded<Value>] = []

    private let timeline: TestTimeline
    private nonisolated(unsafe) let expression: (() -> Value)?
    private var cancellable: AnyCancellable?

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

    internal init<P: Publisher>(
        timeline: TestTimeline,
        publisher: P
    ) where P.Output == Value, P.Failure == Never {
        self.timeline = timeline
        self.expression = nil
        cancellable = publisher.sink { [weak self] value in
            Task { @MainActor [weak self] in
                guard let self else { return }
                let duration = self.timeline.startInstant.duration(to: self.timeline.clock.now)
                self.events.append(.next(duration, value))
            }
        }
    }

    internal init<O: ObservableObject>(
        timeline: TestTimeline,
        object: O,
        expression: @escaping () -> Value
    ) {
        self.timeline = timeline
        self.expression = expression

        // Record the initial value at time zero
        events.append(.next(.zero, expression()))

        // objectWillChange fires before the change, so yield once to read the updated value
        cancellable = object.objectWillChange.sink { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self else { return }
                let duration = self.timeline.startInstant.duration(to: self.timeline.clock.now)
                await Task.yield()
                if let expression = self.expression {
                    self.events.append(.next(duration, expression()))
                }
            }
        }
    }

    private func startObserving() {
        @Sendable func observeNext() {
            withObservationTracking {
                guard let expression else { return }
                _ = expression()
            } onChange: { [weak self] in
                Task { @MainActor in
                    guard let self else { return }

                    let duration = self.timeline.startInstant.duration(to: self.timeline.clock.now)
                    await Task.yield()
                    if let expression = self.expression {
                        self.events.append(.next(duration, expression()))
                    }

                    self.startObserving()
                }
            }
        }
        observeNext()
    }
}
