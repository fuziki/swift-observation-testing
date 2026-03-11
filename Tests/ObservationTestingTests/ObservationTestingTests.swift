import Testing
import Clocks
import Observation
@testable import ObservationTesting

// MARK: - Sample Production Code
@Observable
final class SampleViewModel {
    var title = "A"

    private let clock: AnyClock<Duration>

    init(clock: AnyClock<Duration>) {
        self.clock = clock
    }

    func onTap() async {
        title = "B"
        try? await clock.sleep(for: .seconds(1))
        title = "C"
    }
}

// MARK: - Tests
@Suite("ObservationTesting Tests")
struct ObservationTestingTests {
    @Test("R時間経過と状態変化を正確に記録できること")
    @MainActor
    func testTimelineRecording() async {
        // 1. Setup Timeline & ViewModel
        let timeline = TestTimeline()
        let vm = SampleViewModel(clock: timeline.anyClock)

        // 2. 監視するプロパティと同名の変数でObserverを受け取る
        let title = timeline.observe(vm.title)

        // 3. Schedule Scenarios (順不同で登録しても絶対時間で正しく整列されることを確認)
        timeline.schedule(at: .seconds(3)) {
            await vm.onTap()
        }
        timeline.schedule(at: .seconds(1)) {
            await vm.onTap()
        }

        // 4. Advance Time
        await timeline.advance(by: .seconds(10))

        // 5. Assertions
        #expect(title.events == [
            .next(.zero,       "A"), // 初期状態
            .next(.seconds(1), "B"), // 1秒時点: 1回目のタップ開始
            .next(.seconds(2), "C"), // 2秒時点: 1回目のタップのsleep(1秒)完了
            .next(.seconds(3), "B"), // 3秒時点: 2回目のタップ開始
            .next(.seconds(4), "C"), // 4秒時点: 2回目のタップのsleep(1秒)完了
        ])
    }

    @Test("複雑な条件式(@autoclosure)の変化を監視できること")
    @MainActor
    func testComplexExpressionObservation() async {
        let timeline = TestTimeline()
        let vm = SampleViewModel(clock: timeline.anyClock)

        // titleが "C" かどうかという Bool の状態変化を監視する
        let isTitleC = timeline.observe(vm.title == "C")

        timeline.schedule(at: .seconds(2)) {
            await vm.onTap()
        }

        await timeline.advance(by: .seconds(5))

        // withObservationTracking の onChange は「式の結果」ではなく
        // 「追跡対象プロパティ（title）の変化」で発火する。
        // そのため "A" → "B" の変化（false → false）も記録される。
        #expect(isTitleC.events == [
            .next(.zero,       false), // 初期値 ("A" == "C" → false)
            .next(.seconds(2), false), // "B" への変化で onChange 発火 → false のまま記録
            .next(.seconds(3), true),  // "C" への変化で onChange 発火 → true
        ])
    }
}
