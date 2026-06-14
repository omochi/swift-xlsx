public struct XMLName: Hashable, Sendable {
    public init(rawName: String, namespaceID: XMLNamespaceID?) {
        self.namespaceID = namespaceID

        if let colonIndex = rawName.firstIndex(of: ":") {
            self.prefix = String(rawName[..<colonIndex])
            self.localName = String(rawName[rawName.index(after: colonIndex)...])
        } else {
            self.prefix = nil
            self.localName = rawName
        }
    }

    public var prefix: String?
    public var localName: String
    public var namespaceID: XMLNamespaceID?

    public var rawName: String {
        guard let prefix else {
            return localName
        }
        return "\(prefix):\(localName)"
    }
}
