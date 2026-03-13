# Getting Started with ObservationTesting

Learn how to write timeline-based tests for `@Observable` objects, `ObservableObject` classes, and Combine publishers.

## Overview

`ObservationTesting` replaces wall-clock time with a virtual clock you control entirely. This makes asynchronous state changes fully deterministic: you decide exactly when actions fire, and you can assert the precise sequence of values that result.

## Installation

Add the package to your `Package.swift`:

```swift
.package(url: "https://github.com/fuziki/swift-observation-testing", from: "0.1.0")
```

Then add `ObservationTesting` to your **test target's** dependencies:

```swift
.testTarget(
    name: "MyAppTests",
    dependencies: [
        .product(name: "ObservationTesting", package: "swift-observation-testing"),
    ]
)
```

## Testing `@Observable` properties

Design your view models to accept a clock:

```swift
import Observation

@Observable
final class ViewModel {
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
```

In your test, inject ``TestTimeline/anyClock`` so the view model's internal `sleep` calls are controlled by the timeline:

```swift
import Testing
import ObservationTesting

@Test @MainActor
func onTapUpdatesTitle() async {
    let timeline = TestTimeline()
    let vm = ViewModel(clock: timeline.anyClock)

    // Start recording vm.title. The initial value "A" is captured at time zero.
    let title = timeline.observe(vm.title)

    // Schedule onTap() to fire 1 second into the simulation.
    timeline.schedule(at: .seconds(1)) { await vm.onTap() }

    // Run the simulation for 5 virtual seconds.
    await timeline.advance(by: .seconds(5))

    // Assert the full event history.
    #expect(title.events == [
        .next(.zero,       "A"),  // initial value
        .next(.seconds(1), "B"),  // set immediately inside onTap
        .next(.seconds(2), "C"),  // set after 1-second sleep inside onTap
    ])
}
```

## Testing `ObservableObject` properties

Pass the object and the expression you want to track as separate arguments:

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
func onTapUpdatesTitle() async {
    let timeline = TestTimeline()
    let vm = ViewModel(clock: timeline.anyClock)

    // observe(_:_:) re-evaluates the expression on every objectWillChange notification.
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

## Testing Combine Publishers

Use ``TestTimeline/observe(_:)-4gkbx`` for any publisher with `Failure == Never`.
No initial event is recorded; only values actually emitted appear in ``TestObserver/events``.

```swift
import Testing
import Combine
import ObservationTesting

final class ViewModel {
    let showDialog = PassthroughSubject<Void, Never>()
    private let clock: AnyClock<Duration>

    init(clock: AnyClock<Duration>) { self.clock = clock }

    func onTap() async {
        try? await clock.sleep(for: .seconds(1))
        showDialog.send()
    }
}

@Test @MainActor
func onTapShowsDialog() async {
    let timeline = TestTimeline()
    let vm = ViewModel(clock: timeline.anyClock)

    let showDialog = timeline.observe(vm.showDialog)

    timeline.schedule(at: .seconds(1)) { await vm.onTap() }
    await timeline.advance(by: .seconds(5))

    // The subject fires once, 1 second after onTap starts (which was scheduled at t=1s).
    #expect(showDialog.events.map(\.time) == [.seconds(2)])
}
```

## Filtering consecutive duplicates

When a value is set multiple times to the same thing before truly changing,
``TestObserver/distinctEvents`` collapses consecutive duplicates:

```swift
// events:         [.next(.zero, false), .next(.seconds(2), false), .next(.seconds(3), true)]
// distinctEvents: [.next(.zero, false),                            .next(.seconds(3), true)]
#expect(observer.distinctEvents == [
    .next(.zero,       false),
    .next(.seconds(3), true),
])
```

`distinctEvents` is only available when `Value` conforms to `Equatable`.

## Scheduling multiple actions

You can call ``TestTimeline/schedule(at:action:)`` multiple times before advancing.
Actions are sorted by their scheduled time and run in chronological order regardless
of the order they were registered.

```swift
timeline.schedule(at: .seconds(3)) { await vm.onReset() }
timeline.schedule(at: .seconds(1)) { await vm.onTap() }   // runs first

await timeline.advance(by: .seconds(5))
```
