public final class XMLNamespaceURI: Sendable & Hashable {
    init(_ string: String) {
        self.string = string
    }

    public let string: String

    public static func == (lhs: XMLNamespaceURI, rhs: XMLNamespaceURI) -> Bool {
        lhs === rhs
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self))
    }
}
