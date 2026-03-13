import Combine

extension TestObserver {
    /// Creates an observer that records values emitted by a Combine Publisher.
    convenience init<P: Publisher>(
        timeline: TestTimeline,
        publisher: P
    ) where P.Output == Value, P.Failure == Never {
        self.init(timeline: timeline)
        cancellable = publisher.sink { [weak self] value in
            Task { @MainActor [weak self] in
                guard let self else { return }
                let duration = self.timeline.startInstant.duration(to: self.timeline.clock.now)
                self.events.append(.next(duration, value))
            }
        }
    }
}
