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
}
