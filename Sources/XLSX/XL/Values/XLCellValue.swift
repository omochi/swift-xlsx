public enum XLCellValue: Sendable, Hashable, CustomStringConvertible {
    case number(String)
    case boolean(Bool)
    case string(String)
    case error(String)
    case opaqueSharedString(index: Int)

    public var description: String {
        switch self {
        case let .number(value):
            return value
        case let .boolean(value):
            return value ? "1" : "0"
        case let .string(text):
            return text
        case let .error(value):
            return value
        case let .opaqueSharedString(index):
            return String(index)
        }
    }

    public static func readBool(string: String) -> Bool? {
        if let number = Int(string) {
            return number != 0
        }

        switch string.lowercased() {
        case "true", "t", "yes", "y":
            return true
        case "false", "f", "no", "n":
            return false
        default:
            return nil
        }
    }
}
