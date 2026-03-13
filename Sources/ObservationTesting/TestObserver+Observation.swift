import Observation

extension TestObserver {
    /// Creates an observer that tracks an expression on an `@Observable` object.
    convenience init(
        timeline: TestTimeline,
        expression: @escaping () -> Value
    ) {
        self.init(timeline: timeline)
        self.expression = expression

        // Record the initial value at time zero
        events.append(.next(.zero, expression()))
        startObserving()
    }

    func startObserving() {
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
