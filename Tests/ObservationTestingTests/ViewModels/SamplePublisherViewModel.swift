import Clocks
import Combine

@MainActor
final class SamplePublisherViewModel {
    var showDialog = PassthroughSubject<Void, Never>()

    private let clock: AnyClock<Duration>

    init(clock: AnyClock<Duration>) {
        self.clock = clock
    }

    func onTap() async {
        try? await clock.sleep(for: .seconds(1))
        showDialog.send()
    }
}
