public enum XLCellValue: Sendable & Hashable {
    case string(String)
    case opaqueSharedString(index: Int)

    public init(rawValue: String) {
        self = .string(rawValue)
    }

    public var rawValue: String {
        switch self {
        case let .string(text):
            return text
        case let .opaqueSharedString(index):
            return String(index)
        }
    }
}
