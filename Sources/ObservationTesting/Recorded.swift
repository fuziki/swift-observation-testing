import Foundation

/// Records what value occurred at which point in virtual time.
public enum Recorded<Value: Equatable>: Equatable, CustomStringConvertible {
    case next(Duration, Value)

    public var description: String {
        switch self {
        case .next(let time, let value):
            return "next(\(time), \(value))"
        }
    }
}
