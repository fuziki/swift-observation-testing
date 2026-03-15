public extension TestObserver {
    /// The virtual times at which events were recorded, in chronological order.
    ///
    /// Use `eventTimes` when `Value` is not `Equatable` (e.g. `Void`) and you only need to
    /// assert the number of emissions and when they occurred.
    ///
    /// ```swift
    /// // For a Void publisher where values cannot be compared:
    /// let showDialog = timeline.observe(vm.showDialog)
    /// await timeline.advance(by: .seconds(5))
    ///
    /// #expect(showDialog.eventTimes == [.seconds(1), .seconds(3)])
    /// ```
    var eventTimes: [Duration] {
        events.map(\.time)
    }
}
