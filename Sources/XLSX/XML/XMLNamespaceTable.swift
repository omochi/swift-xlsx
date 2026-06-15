public struct XMLNamespaceTable: Sendable {
    public init() {}

    private var entries: [(prefix: String?, uri: XMLNamespaceURI)] = []

    public var declarations: [(prefix: String?, uri: XMLNamespaceURI)] {
        entries
    }

    public var isEmpty: Bool {
        entries.isEmpty
    }

    public mutating func declare(prefix: String? = nil, uri: XMLNamespaceURI) {
        if let index = entries.firstIndex(where: { $0.prefix == prefix }) {
            entries[index].uri = uri
        } else {
            entries.append((prefix: prefix, uri: uri))
        }
    }

    public func declared(prefix: String? = nil, uri: XMLNamespaceURI) -> Self {
        var table = self
        table.declare(prefix: prefix, uri: uri)
        return table
    }

    public func uri(for prefix: String? = nil) -> XMLNamespaceURI? {
        entries.first { $0.prefix == prefix }?.uri
    }
}
