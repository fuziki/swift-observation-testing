import Combine

extension TestObserver {
    /// Creates an observer that tracks an expression on an `ObservableObject`.
    convenience init<O: ObservableObject>(
        timeline: TestTimeline,
        object: O,
        expression: @escaping () -> Value
    ) {
        self.init(timeline: timeline)
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
}
