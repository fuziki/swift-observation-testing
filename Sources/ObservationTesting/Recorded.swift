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
}

extension Recorded: Equatable where Value: Equatable {}

extension Recorded where Value == Void {
    public static func == (lhs: Recorded<Void>, rhs: Recorded<Void>) -> Bool {
        switch (lhs, rhs) {
        case (.next(let lTime, _), .next(let rTime, _)):
            return lTime == rTime
        }
    }
}
