import Clocks
import Observation

@MainActor
@Observable
final class SampleObservationViewModel {
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
