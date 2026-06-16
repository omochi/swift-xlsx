public enum XLSharedStringRecord: Sendable, Hashable, CustomStringConvertible {
    case text(String)
    case opaque(xmlString: String)
}

extension XLSharedStringRecord {
    public var description: String {
        switch self {
        case let .text(text):
            return text
        case let .opaque(xmlString):
            return xmlString
        }
    }
}
