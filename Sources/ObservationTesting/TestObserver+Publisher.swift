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
                // Explicit `self` is required: older Swift versions do not allow implicit self
                // after `guard let self` in a nested closure, causing a compile error in CI.
                // swiftlint:disable:next redundant_self
                self.events.append(.next(duration, value))
            }
        }
    }
}
