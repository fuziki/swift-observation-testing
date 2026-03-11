import Foundation

/// 仮想時間上のどのタイミングで、どのような値が発生したかを記録します。
public enum Recorded<Value: Equatable>: Equatable, CustomStringConvertible {
    case next(Duration, Value)

    public var description: String {
        switch self {
        case .next(let time, let value):
            return "next(\(time), \(value))"
        }
    }
}
