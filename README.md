# swift-observation-testing

A testing utility for Swift's Observation framework. It lets you record how observed values change over virtual time, making timeline-based assertions straightforward.

## Requirements

- Swift 6.0+
- iOS 17+ / macOS 14+ / tvOS 17+ / watchOS 10+

## Installation

Add the package via Swift Package Manager:

```swift
.package(url: "https://github.com/fuziki/swift-observation-testing", from: "0.1.0")
```

Then add `ObservationTesting` to your test target's dependencies.

## Usage

### Observing `@Observable` properties

```swift
import Testing
import Observation
import ObservationTesting

@Observable
final class ViewModel {
    var title = "A"
    private let clock: AnyClock<Duration>

    init(clock: AnyClock<Duration>) { self.clock = clock }

    func onTap() async {
        title = "B"
        try? await clock.sleep(for: .seconds(1))
        title = "C"
    }
}

@Test @MainActor
func example() async {
    let timeline = TestTimeline()
    let vm = ViewModel(clock: timeline.anyClock)

    let title = timeline.observe(vm.title)

    timeline.schedule(at: .seconds(1)) { await vm.onTap() }

    await timeline.advance(by: .seconds(5))

    #expect(title.events == [
        .next(.zero,       "A"),
        .next(.seconds(1), "B"),
        .next(.seconds(2), "C"),
    ])
}
```

### Observing Combine Publishers

`timeline.observe` also accepts any `Publisher` with `Failure == Never`. Events are recorded with the virtual time at which they are emitted. No initial event is recorded.

```swift
import Testing
import Combine
import Observation
import ObservationTesting

@Observable
@MainActor
final class ViewModel {
    var showDialog = PassthroughSubject<Void, Never>()
    private let clock: AnyClock<Duration>

    init(clock: AnyClock<Duration>) { self.clock = clock }

    func onTap() async {
        try? await clock.sleep(for: .seconds(1))
        showDialog.send()
    }
}

@Test @MainActor
func example() async {
    let timeline = TestTimeline()
    let vm = ViewModel(clock: timeline.anyClock)

    let showDialog = timeline.observe(vm.showDialog)

    timeline.schedule(at: .seconds(1)) { await vm.onTap() }

    await timeline.advance(by: .seconds(5))

    #expect(showDialog.events.map(\.time) == [
        .seconds(2),
    ])
}
```

## API

### `TestTimeline`

Manages virtual time and schedules actions.

| Method | Description |
|---|---|
| `observe(_ expression:)` | Starts observing an `@Observable` expression and returns a `TestObserver` |
| `observe(_ publisher:)` | Starts observing a `Publisher` (`Failure == Never`) and returns a `TestObserver` |
| `schedule(at:action:)` | Schedules an action at an absolute time from test start |
| `advance(by:)` | Advances virtual time and executes scheduled actions |
| `anyClock` | A type-erased clock for injection into production code |

### `TestObserver<Value>`

Holds the recorded history of an observed expression.

| Property | Description |
|---|---|
| `events: [Recorded<Value>]` | Sequence of recorded values with their timestamps |

### `Recorded<Value>`

Represents a single recorded event.

```swift
.next(Duration, Value)
```
