# swift-observation-testing

[![Test](https://github.com/fuziki/swift-observation-testing/actions/workflows/test.yml/badge.svg)](https://github.com/fuziki/swift-observation-testing/actions/workflows/test.yml)
[![Swift 6.0+](https://img.shields.io/badge/Swift-6.0%2B-F05138?logo=swift)](https://swift.org)
[![Platforms](https://img.shields.io/badge/platforms-iOS%2017%20%7C%20macOS%2014%20%7C%20tvOS%2017%20%7C%20watchOS%2010-lightgrey)](Package.swift)
[![License: MIT](https://img.shields.io/github/license/fuziki/swift-observation-testing)](LICENSE)
[![Documentation](https://img.shields.io/badge/Documentation-DocC-blue?logo=swift)](https://fuziki.github.io/swift-observation-testing/documentation/observationtesting/)

[English](README.md)

<!-- NOTE: これは日本語版 README です。内容を追加・更新・削除した場合は、README.md（英語版）にも同じ変更を加えてください。 -->

Swift の Observation フレームワークおよび Combine の `ObservableObject` 向けテストユーティリティです。観察対象の値が仮想時間上でどのように変化するかを記録し、タイムラインベースのアサーションを簡単に記述できます。

## 要件

- Swift 6.0+
- iOS 17+ / macOS 14+ / tvOS 17+ / watchOS 10+

## インストール

Swift Package Manager でパッケージを追加します:

```swift
.package(url: "https://github.com/fuziki/swift-observation-testing", from: "0.1.0")
```

その後、テストターゲットの dependencies に `ObservationTesting` を追加してください。

## 使い方

### `@Observable` プロパティの観察

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

### `ObservableObject` プロパティの観察

オブジェクトとプロパティの式をセットで渡します。式は `objectWillChange` 通知のたびに再評価されます。

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

### Combine Publisher の観察

`timeline.observe` は `Failure == Never` の任意の `Publisher` も受け付けます。イベントは Publisher が値を発行した仮想時刻とともに記録されます。初期イベントは記録されません。

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

### `distinctEvents` で連続する重複を除外する

`distinctEvents` は同じ値が連続するイベントを除去し、最初の発生のみを残します。実際の状態遷移だけに注目したい場合に便利です。

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

仮想時間を管理し、アクションをスケジュールします。

| メソッド | 説明 |
|---------|------|
| `observe(_ expression:)` | `@Observable` の式の観察を開始し、`TestObserver` を返す |
| `observe(_ object:_ expression:)` | `ObservableObject` の式の観察を開始し、`TestObserver` を返す |
| `observe(_ publisher:)` | `Publisher`（`Failure == Never`）の観察を開始し、`TestObserver` を返す |
| `schedule(at:action:)` | テスト開始からの絶対時刻にアクションをスケジュールする |
| `advance(by:)` | 仮想時間を進め、スケジュール済みのアクションを実行する |
| `anyClock` | プロダクションコードへの注入用に型消去されたクロック |

### `TestObserver<Value>`

観察した式の記録を保持します。

| プロパティ | 説明 |
|-----------|------|
| `events: [Recorded<Value>]` | タイムスタンプ付きで記録されたすべての値 |
| `distinctEvents: [Recorded<Value>]` | 連続する重複値を除去したイベント列（`Value: Equatable`） |

### `Recorded<Value>`

単一の記録されたイベントを表します。

```swift
.next(Duration, Value)
```

| プロパティ | 説明 |
|-----------|------|
| `time: Duration` | イベントが記録された仮想時刻 |
| `value: Value` | 記録された値 |
