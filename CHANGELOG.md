# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.1.0] - 2026-03-13

### Added

- `TestTimeline` for managing virtual time in tests
  - `observe(_ expression:)` — observe `@Observable` properties
  - `observe(_ object:_ expression:)` — observe `ObservableObject` properties
  - `observe(_ publisher:)` — observe Combine `Publisher` (`Failure == Never`)
  - `schedule(at:action:)` — schedule an async action at an absolute virtual time
  - `advance(by:)` — advance virtual time and execute scheduled actions
  - `anyClock` — type-erased clock for injecting into production code
- `TestObserver<Value>` for inspecting recorded events
  - `events` — all recorded values with timestamps
  - `distinctEvents` — events with consecutive duplicate values removed (`Value: Equatable`)
- `Recorded<Value>` — a single recorded event with `time` and `value` properties
- DocC documentation published to GitHub Pages
- CI with GitHub Actions (build and test on every push and pull request)
- SwiftLint and SwiftFormat integration for consistent code style

[Unreleased]: https://github.com/fuziki/swift-observation-testing/compare/0.1.0...HEAD
[0.1.0]: https://github.com/fuziki/swift-observation-testing/releases/tag/0.1.0
