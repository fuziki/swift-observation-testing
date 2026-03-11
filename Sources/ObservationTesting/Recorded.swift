import Foundation

/// Records what value occurred at which point in virtual time.
public enum Recorded<Value>: CustomStringConvertible {
    case next(Duration, Value)

    public var description: String {
        switch self {
        case .next(let time, let value):
            return "next(\(time), \(value))"
        }
    }

    public var time: Duration {
        switch self {
        case .next(let duration, _):
            duration
        }
    }
}

extension Recorded: Equatable where Value: Equatable {}
