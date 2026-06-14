import MemberwiseInit

@MemberwiseInit(.public)
public struct XMLNamespaceTable: Sendable {
    public var uriToID: [String: XMLNamespaceID] = [:]
    public var idToURI: [String] = []

    public mutating func intern(_ uri: String?) -> XMLNamespaceID? {
        guard let uri else {
            return nil
        }
        if let id = uriToID[uri] {
            return id
        }

        let id = XMLNamespaceID(rawValue: idToURI.count)
        uriToID[uri] = id
        idToURI.append(uri)
        return id
    }

    public func uri(for id: XMLNamespaceID) -> String {
        idToURI[id.rawValue]
    }
}
