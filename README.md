# swift-observation-testing

[![Test](https://github.com/fuziki/swift-observation-testing/actions/workflows/test.yml/badge.svg)](https://github.com/fuziki/swift-observation-testing/actions/workflows/test.yml)
[![Swift 6.0+](https://img.shields.io/badge/Swift-6.0%2B-F05138?logo=swift)](https://swift.org)
[![Platforms](https://img.shields.io/badge/platforms-iOS%2017%20%7C%20macOS%2014%20%7C%20tvOS%2017%20%7C%20watchOS%2010-lightgrey)](Package.swift)
[![License: MIT](https://img.shields.io/github/license/fuziki/swift-observation-testing)](LICENSE)
[![Documentation](https://img.shields.io/badge/Documentation-DocC-blue?logo=swift)](https://fuziki.github.io/swift-observation-testing/documentation/observationtesting/)

[日本語](README.ja.md)

<!-- NOTE: This is the English README. When you add, update, or remove any content here, apply the same changes to README.ja.md (Japanese) as well. -->

A testing utility for Swift's Observation framework and Combine's `ObservableObject`. It lets you record how observed values change over virtual time, making timeline-based assertions straightforward.

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

### Observing `ObservableObject` properties

Pass the object and an expression together. The expression is re-evaluated on every `objectWillChange` notification.

```swift
import Testing
import Combine
import ObservationTesting

final class ViewModel: ObservableObject {
    @Published var title = "A"
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

    let title = timeline.observe(vm, vm.title)

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
import ObservationTesting

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

### Filtering consecutive duplicates with `distinctEvents`

`distinctEvents` removes consecutive events with the same value, keeping only the first occurrence. This is useful when you only care about actual state transitions.

```swift
// events:        [false(0s), false(2s), true(3s)]
// distinctEvents: [false(0s),            true(3s)]
#expect(isTitleC.distinctEvents == [
    .next(.zero,       false),
    .next(.seconds(3), true),
])
```

## API

### `TestTimeline`

Manages virtual time and schedules actions.

| Method | Description |
|---|---|
| `observe(_ expression:)` | Starts observing an `@Observable` expression and returns a `TestObserver` |
| `observe(_ object:_ expression:)` | Starts observing an `ObservableObject` expression and returns a `TestObserver` |
| `observe(_ publisher:)` | Starts observing a `Publisher` (`Failure == Never`) and returns a `TestObserver` |
| `schedule(at:action:)` | Schedules an action at an absolute time from test start |
| `advance(by:)` | Advances virtual time and executes scheduled actions |
| `anyClock` | A type-erased clock for injection into production code |

### `TestObserver<Value>`

Holds the recorded history of an observed expression.

| Property | Description |
|---|---|
| `events: [Recorded<Value>]` | All recorded values with their timestamps |
| `distinctEvents: [Recorded<Value>]` | Events with consecutive duplicate values removed (`Value: Equatable`) |

### `Recorded<Value>`

Represents a single recorded event.

```swift
.next(Duration, Value)
```

| Property | Description |
|---|---|
| `time: Duration` | Virtual time at which the event was recorded |
| `value: Value` | The recorded value |
