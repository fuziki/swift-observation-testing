---
name: Bug report
about: Report a bug in ObservationTesting
title: '[Bug] '
labels: bug
assignees: ''

---

## Describe the Bug

<!-- A clear and concise description of the bug. -->

## API Used

- [ ] `@Observable` (`TestObserver+Observation`)
- [ ] `ObservableObject` (`TestObserver+ObservableObject`)
- [ ] `Publisher` (`TestObserver+Publisher`)
- [ ] `distinctEvents`
- [ ] Other:

## Reproduction

<!-- Minimal test code that reproduces the issue. -->

```swift
func testExample() async {
    let timeline = await TestTimeline()
    // ...
}
```

## Expected `events`

```
[next(0 seconds, ...), next(1 seconds, ...)]
```

## Actual `events`

```
[next(0 seconds, ...), ...]
```

## Environment

- ObservationTesting version:
- Swift version:
- Xcode version:
- OS:

## Additional Context

<!-- Any other relevant context. -->
