# Contributing to swift-observation-testing

Thank you for your interest in contributing! This document explains how to get started and what to expect when submitting changes.

## Table of Contents

- [Getting Started](#getting-started)
- [Development Workflow](#development-workflow)
- [Code Style](#code-style)
- [Commit Messages](#commit-messages)
- [Pull Requests](#pull-requests)
- [Reporting Bugs](#reporting-bugs)
- [Requesting Features](#requesting-features)

## Getting Started

### Prerequisites

- Xcode 16+ with Swift 6.0+
- macOS 14+

### Setup

1. Fork this repository and clone your fork:

   ```sh
   git clone https://github.com/<your-username>/swift-observation-testing.git
   cd swift-observation-testing
   ```

2. Verify everything builds and the tests pass:

   ```sh
   make test
   ```

## Development Workflow

### Branching

Create a descriptive branch from `main` for your change:

```sh
git checkout -b fix/observer-memory-leak
git checkout -b feature/add-visionos-support
```

### Building and testing

| Command | Description |
|---------|-------------|
| `make test` | Build and run the full test suite |
| `make fix` | Run SwiftLint auto-fix and SwiftFormat |
| `make lint` | Lint only (no format) |
| `make format` | Format only (no lint) |
| `make docc` | Build DocC documentation locally |

After any change to `Sources/` or `Tests/`, always run:

```sh
make test   # must pass
make fix    # apply lint fixes and formatting
```

Resolve any remaining SwiftLint warnings before opening a pull request.

## Code Style

This project uses [SwiftLint](https://github.com/realm/SwiftLint) and [SwiftFormat](https://github.com/nicklockwood/SwiftFormat) to enforce a consistent style. The rules are defined in [.swiftlint.yml](.swiftlint.yml) and [.swiftformat](.swiftformat).

Running `make fix` handles both tools automatically. Do not skip this step — the CI will fail if linting or formatting is off.

Key style points:

- 4-space indentation
- Maximum line length of 120 characters
- Imports sorted alphabetically
- `self.` omitted where not required

## Commit Messages

- **Language**: English
- **Length**: 50 characters or fewer
- **Style**: Start with an imperative verb

```
Add visionOS platform support
Fix memory leak in TestObserver
Update README API table
```

## Pull Requests

1. Ensure `make test` passes and `make fix` has been run with no remaining warnings.
2. If your change adds, removes, or modifies a public API (`TestTimeline`, `TestObserver`, `Recorded`, etc.), update `README.md` in the same PR.
3. Open a pull request against `main` and fill in the [PR template](.github/PULL_REQUEST_TEMPLATE.md).
4. Keep changes focused — one logical change per PR makes review faster.

PRs from forks are welcome. CI will run automatically once a maintainer approves the first run.

## Reporting Bugs

Open an issue using the [Bug report](.github/ISSUE_TEMPLATE/bug_report.md) template. Please include:

- A minimal test case that reproduces the problem
- The expected and actual `events` output
- Your ObservationTesting version, Swift version, Xcode version, and OS

## Requesting Features

Open an issue using the [Feature request](.github/ISSUE_TEMPLATE/feature_request.md) template. Describe the testing scenario that is difficult today and your proposed API, along with any alternatives you considered.

For significant API changes, opening an issue for discussion before writing code is encouraged — it avoids wasted effort if the direction needs adjustment.
