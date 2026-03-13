import Foundation
import Clocks
import Combine

/// Records changes in the value of the specified expression along with virtual time.
@MainActor
public final class TestObserver<Value> {
    /// History of recorded events
    public internal(set) var events: [Recorded<Value>] = []

    let timeline: TestTimeline
    nonisolated(unsafe) var expression: (() -> Value)?
    var cancellable: AnyCancellable?

    init(timeline: TestTimeline) {
        self.timeline = timeline
    }
}
