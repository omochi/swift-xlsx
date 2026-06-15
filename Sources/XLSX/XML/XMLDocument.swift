import Foundation

public final class XMLDocument: XMLNode {
    public init(
        children: [XMLNode] = []
    ) {
        self.namespaceURIs = [:]
        self.childNodes = children
        super.init()
        for child in children {
            child._setParent(self)
        }
    }

    private var namespaceURIs: [String: XMLNamespaceURI]
    public var childNodes: [XMLNode]

    public override var kind: XMLNodeKind {
        .document
    }

    public override var children: [XMLNode] {
        get { childNodes }
        set { childNodes = newValue }
    }

    public func element(name: String) -> XMLElement? {
        children.compactMap { $0 as? XMLElement }.first { $0.name.name == name }
    }

    public func data() -> Data {
        Data(xmlString.utf8)
    }

    public var xmlString: String {
        var serializer = XMLSerializer()
        return serializer.serialize(document: self)
    }

    public func internNamespaceURI(_ string: String) -> XMLNamespaceURI {
        if let uri = namespaceURIs[string] {
            return uri
        }

        let uri = XMLNamespaceURI(string)
        namespaceURIs[string] = uri
        return uri
    }
}
