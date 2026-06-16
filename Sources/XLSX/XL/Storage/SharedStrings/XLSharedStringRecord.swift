public enum XLSharedStringRecord: Sendable & Hashable {
    case text(String)
    case opaque(originalChildIndex: Int)
}
