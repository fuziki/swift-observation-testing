import Clocks
import Testing
@testable import ObservationTesting

@Suite("ObservableObject Tests")
@MainActor
struct ObservableObjectTests {
    @Test("Can accurately record time progression and state changes")
    func testTimelineRecording() async {
        // 1. Setup Timeline & ViewModel
        let timeline = TestTimeline()
        let vm = SampleObservableObjectViewModel(clock: timeline.anyClock)

        // 2. Observe the @Published property via ObservableObject + expression
        let title = timeline.observe(vm, vm.title)

        // 3. Schedule Scenarios
        timeline.schedule(at: .seconds(1)) {
            await vm.onTap()
        }
        timeline.schedule(at: .seconds(3)) {
            await vm.onTap()
        }

        // 4. Advance Time
        await timeline.advance(by: .seconds(10))

        // 5. Assertions
        #expect(title.events == [
            .next(.zero,       "A"), // initial state
            .next(.seconds(1), "B"), // at 1s: first tap begins
            .next(.seconds(2), "C"), // at 2s: first tap's sleep(1s) completes
            .next(.seconds(3), "B"), // at 3s: second tap begins
            .next(.seconds(4), "C"), // at 4s: second tap's sleep(1s) completes
        ])
    }

    @Test("Can observe a computed expression on ObservableObject")
    func testExpressionObservation() async {
        let timeline = TestTimeline()
        let vm = SampleObservableObjectViewModel(clock: timeline.anyClock)

        // Observe the Bool state change of whether title equals "C"
        let isTitleC = timeline.observe(vm, vm.title == "C")

        timeline.schedule(at: .seconds(2)) {
            await vm.onTap()
        }

        await timeline.advance(by: .seconds(5))

        // objectWillChange fires before each mutation, so both "A"→"B" and "B"→"C" produce entries.
        #expect(isTitleC.events == [
            .next(.zero,       false), // initial value ("A" == "C" → false)
            .next(.seconds(2), false), // onChange fires on change to "B" → false
            .next(.seconds(3), true),  // onChange fires on change to "C" → true
        ])
    }
}
