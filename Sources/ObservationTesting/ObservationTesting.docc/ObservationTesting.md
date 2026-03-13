# ``ObservationTesting``

A testing utility for Swift's Observation framework and Combine's `ObservableObject` that lets you record how observed values change over virtual time.

## Overview

`ObservationTesting` provides a timeline-based API for writing deterministic tests against state that changes asynchronously. Instead of waiting for real time to pass, you control a virtual clock and assert the exact sequence of values produced by your observable objects or Combine publishers.

### Core types

| Type | Role |
|------|------|
| ``TestTimeline`` | Creates and advances virtual time; entry point for all tests |
| ``TestObserver`` | Holds the recorded event history for a single observed expression |
| ``Recorded`` | A value paired with the virtual time at which it was captured |

### Basic workflow

1. Create a ``TestTimeline`` and inject ``TestTimeline/anyClock`` into your system under test.
2. Call one of the `observe` overloads to start recording changes.
3. Schedule actions with ``TestTimeline/schedule(at:action:)``.
4. Advance time with ``TestTimeline/advance(by:)``.
5. Assert on ``TestObserver/events`` or ``TestObserver/distinctEvents``.

```swift
@Test @MainActor
func onTapUpdatesTitle() async {
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

## Topics

### Getting Started

- <doc:GettingStarted>

### Timeline Management

- ``TestTimeline``

### Recording Observations

- ``TestObserver``
- ``Recorded``
