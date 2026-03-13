public extension TestObserver where Value: Equatable {
    /// Events with consecutive duplicate values removed, keeping only the first occurrence.
    ///
    /// Use `distinctEvents` when you care about *state transitions* rather than every
    /// intermediate update. Consecutive events that carry the same value are collapsed
    /// into the first one; non-consecutive duplicates are preserved.
    ///
    /// ```swift
    /// // events:         [.next(.zero, false), .next(.seconds(2), false), .next(.seconds(3), true)]
    /// // distinctEvents: [.next(.zero, false),                            .next(.seconds(3), true)]
    /// #expect(observer.distinctEvents == [
    ///     .next(.zero,       false),
    ///     .next(.seconds(3), true),
    /// ])
    /// ```
    ///
    /// - Note: Only *consecutive* duplicates are removed. If the value returns to a
    ///   previous state after changing, both transitions are kept.
    var distinctEvents: [Recorded<Value>] {
        events.reduce(into: []) { result, recorded in
            if result.last.map({ $0.value != recorded.value }) ?? true {
                result.append(recorded)
            }
        }
    }
}
