extension TestObserver where Value: Equatable {
    /// Events with consecutive duplicate values removed, keeping only the first occurrence.
    public var distinctEvents: [Recorded<Value>] {
        events.reduce(into: []) { result, recorded in
            if result.last.map({ $0.value != recorded.value }) ?? true {
                result.append(recorded)
            }
        }
    }
}
