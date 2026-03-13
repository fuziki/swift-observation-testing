import Foundation

/// Represents a single event captured by a ``TestObserver``.
///
/// Each `Recorded` value pairs a virtual timestamp with the value observed at that
/// instant. Currently the only case is ``next(_:_:)``, which covers normal value
/// emissions. Additional cases (e.g. completion or error) may be added in future
/// versions.
///
/// ## Comparing events
///
/// `Recorded` conforms to `Equatable` when `Value` does, so you can compare entire
/// event arrays in a single assertion:
///
/// ```swift
/// #expect(title.events == [
///     .next(.zero,       "A"),
///     .next(.seconds(1), "B"),
///     .next(.seconds(2), "C"),
/// ])
/// ```
public enum Recorded<Value>: CustomStringConvertible {
    /// An event that carries a value at a specific point in virtual time.
    ///
    /// - Parameters:
    ///   - time: The virtual time elapsed since test start when the value was captured.
    ///   - value: The observed value at `time`.
    case next(Duration, Value)

    /// A human-readable representation of this event, e.g. `next(1.0 seconds, "Hello")`.
    public var description: String {
        switch self {
        case let .next(time, value):
            "next(\(time), \(value))"
        }
    }

    /// The virtual time at which this event was recorded.
    public var time: Duration {
        switch self {
        case let .next(duration, _):
            duration
        }
    }

    /// The value captured at ``time``.
    public var value: Value {
        switch self {
        case let .next(_, value):
            value
        }
    }
}

extension Recorded: Equatable where Value: Equatable {}
