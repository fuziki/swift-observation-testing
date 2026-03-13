import Testing
import Clocks
@testable import ObservationTesting

@Suite("Observation Tests")
@MainActor
struct ObservationTests {
    @Test("Can accurately record time progression and state changes")
    func testTimelineRecording() async {
        // 1. Setup Timeline & ViewModel
        let timeline = TestTimeline()
        let vm = SampleObservationViewModel(clock: timeline.anyClock)

        // 2. Receive the Observer in a variable with the same name as the observed property
        let title = timeline.observe(vm.title)

        // 3. Schedule Scenarios (verify that they are correctly sorted by absolute time regardless of registration order)
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
            .next(.zero,       "A"), // initial state
            .next(.seconds(1), "B"), // at 1s: first tap begins
            .next(.seconds(2), "C"), // at 2s: first tap's sleep(1s) completes
            .next(.seconds(3), "B"), // at 3s: second tap begins
            .next(.seconds(4), "C"), // at 4s: second tap's sleep(1s) completes
        ])
    }

    @Test("Can observe changes in a complex expression (@autoclosure)")
    func testComplexExpressionObservation() async {
        let timeline = TestTimeline()
        let vm = SampleObservationViewModel(clock: timeline.anyClock)

        // Observe the Bool state change of whether title equals "C"
        let isTitleC = timeline.observe(vm.title == "C")

        timeline.schedule(at: .seconds(2)) {
            await vm.onTap()
        }

        await timeline.advance(by: .seconds(5))

        // withObservationTracking's onChange fires on changes to the tracked property (title),
        // not on changes to the expression result.
        // Therefore, the "A" → "B" change (false → false) is also recorded.
        #expect(isTitleC.events == [
            .next(.zero,       false), // initial value ("A" == "C" → false)
            .next(.seconds(2), false), // onChange fires on change to "B" → recorded as false
            .next(.seconds(3), true),  // onChange fires on change to "C" → true
        ])
    }
}
