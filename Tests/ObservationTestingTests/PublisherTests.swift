import Clocks
import Testing
@testable import ObservationTesting

@Suite("Publisher Tests")
@MainActor
struct PublisherTests {
    @Test("Can record events emitted by a Publisher")
    func testPublisherObservation() async {
        let timeline = TestTimeline()
        let vm = SamplePublisherViewModel(clock: timeline.anyClock)

        let showDialog = timeline.observe(vm.showDialog)

        timeline.schedule(at: .seconds(1)) {
            await vm.onTap()
        }
        timeline.schedule(at: .seconds(3)) {
            await vm.onTap()
        }

        await timeline.advance(by: .seconds(10))

        #expect(showDialog.events.map(\.time) == [
            .seconds(2), // at 2s: first tap's sleep(1s) completes
            .seconds(4), // at 4s: second tap's sleep(1s) completes
        ])
    }
}
