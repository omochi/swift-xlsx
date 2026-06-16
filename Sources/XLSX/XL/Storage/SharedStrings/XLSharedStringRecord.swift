public enum XLSharedStringRecord: Sendable & Equatable {
    case text(String)
    case opaque(originalChildIndex: Int)
}
