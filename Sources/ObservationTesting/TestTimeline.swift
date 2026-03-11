import Foundation
import Clocks

/// 仮想時間の管理と、指定した時間でのアクション実行（シナリオ）を制御します。
@MainActor
public final class TestTimeline {
    public let clock = TestClock<Duration>()
    public let startInstant: TestClock<Duration>.Instant

    /// プロダクションコードへ注入するための、型消去されたClock
    public var anyClock: AnyClock<Duration> { AnyClock(clock) }

    private var scheduledActions: [(time: Duration, action: @MainActor () async -> Void)] = []

    public init() {
        startInstant = clock.now
    }

    /// 監視対象を登録し、TestObserverを生成します
    public func observe<Value: Equatable>(
        _ expression: @autoclosure @escaping @MainActor () -> Value
    ) -> TestObserver<Value> {
        TestObserver(timeline: self, expression: expression)
    }

    /// テスト開始時(0秒)からの絶対時間でアクションを予約します
    public func schedule(at time: Duration, action: @escaping @MainActor () async -> Void) {
        scheduledActions.append((time, action))
    }

    /// 仮想時間を指定した分だけ進め、予約されたシナリオを正確な時間順に実行します
    public func advance(by duration: Duration) async {
        // 予約されたアクションを絶対時間で昇順ソートしてからTestClockに登録
        let sorted = scheduledActions.sorted { $0.time < $1.time }
        for (time, action) in sorted {
            let targetInstant = startInstant.advanced(by: time)
            Task { @MainActor in
                try? await clock.sleep(until: targetInstant)
                await action()
            }
        }
        scheduledActions.removeAll()

        // 登録したTask群が確実に `clock.sleep` に到達するのを待つ
        await Task.yield()
        await Task.yield()

        // 仮想時間を進める（指定時間順に自動的にTaskが発火・再開します）
        await clock.advance(by: duration)

        // Observationの非同期な更新処理が完了し、
        // TestObserverのeventsに書き込まれるのを待つ
        await Task.yield()
        await Task.yield()
    }
}
