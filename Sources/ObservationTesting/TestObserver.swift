import Foundation
import Clocks
import Observation

/// 指定された式の値の変化を、仮想時間と共に記録します。
@MainActor
public final class TestObserver<Value: Equatable> {
    /// 記録されたイベントの履歴
    public private(set) var events: [Recorded<Value>] = []

    private let timeline: TestTimeline
    private nonisolated(unsafe) let expression: () -> Value

    internal init(
        timeline: TestTimeline,
        expression: @escaping () -> Value
    ) {
        self.timeline = timeline
        self.expression = expression

        // 0秒時点の初期値を記録
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
