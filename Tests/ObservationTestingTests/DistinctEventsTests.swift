import Clocks
import Testing
@testable import ObservationTesting

@Suite("Distinct Tests")
@MainActor
struct DistinctTests {
    @Test("Removes consecutive duplicate values, keeping the first occurrence")
    func testDistinct() async {
        let timeline = TestTimeline()
        let vm = SampleObservationViewModel(clock: timeline.anyClock)

        // events will be: [false(0s), false(2s), true(3s)]
        // because onChange fires on every property change regardless of expression result
        let isTitleC = timeline.observe(vm.title == "C")

        timeline.schedule(at: .seconds(2)) {
            await vm.onTap()
        }

        await timeline.advance(by: .seconds(5))

        // Confirm raw events contain the consecutive false
        #expect(isTitleC.events == [
            .next(.zero,       false),
            .next(.seconds(2), false), // duplicate: "A"→"B" fires onChange but expression is still false
            .next(.seconds(3), true),
        ])

        // distinct deduplicates consecutive equal values
        #expect(isTitleC.distinctEvents == [
            .next(.zero,       false), // first false is kept
            .next(.seconds(3), true),  // transition to true is kept
        ])
    }

    @Test("Keeps all events when no consecutive duplicates exist")
    func testDistinctWithNoDuplicates() async {
        let timeline = TestTimeline()
        let vm = SampleObservationViewModel(clock: timeline.anyClock)

        let title = timeline.observe(vm.title)

        timeline.schedule(at: .seconds(1)) {
            await vm.onTap()
        }

        await timeline.advance(by: .seconds(5))

        // No consecutive duplicates: "A" → "B" → "C"
        #expect(title.distinctEvents == title.events)
    }

    @Test("Removes consecutive duplicates across multiple cycles")
    func testDistinctMultipleCycles() async {
        let timeline = TestTimeline()
        let vm = SampleObservationViewModel(clock: timeline.anyClock)

        // isTitleC pattern: false(0s), false(1s), true(2s), false(3s), false(4s), true(4s)
        let isTitleC = timeline.observe(vm.title == "C")

        timeline.schedule(at: .seconds(1)) {
            await vm.onTap()
        }
        timeline.schedule(at: .seconds(3)) {
            await vm.onTap()
        }

        await timeline.advance(by: .seconds(10))

        #expect(isTitleC.distinctEvents == [
            .next(.zero,       false),
            .next(.seconds(2), true),
            .next(.seconds(3), false),
            .next(.seconds(4), true),  // 2nd tap: 3s start + 1s sleep = 4s
        ])
    }
}
