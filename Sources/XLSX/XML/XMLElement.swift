public final class XMLElement: XMLNode {
    public init(
        name: XMLName,
        namespaces: XMLNamespaceTable = XMLNamespaceTable(),
        attributes: [XMLAttribute] = [],
        children: [XMLNode] = []
    ) {
        self.name = name
        self.namespaces = namespaces
        self.attributes = attributes
        self.childNodes = children
        super.init()
        for child in children {
            child._setParent(self)
        }
    }

    public var name: XMLName
    public var namespaces: XMLNamespaceTable
    public var attributes: [XMLAttribute]
    public var childNodes: [XMLNode]

    public override var kind: XMLNodeKind {
        .element
    }

    public override var children: [XMLNode] {
        get { childNodes }
        set { childNodes = newValue }
    }

    public override func clone() -> Self {
        XMLElement(
            name: name,
            namespaces: namespaces,
            attributes: attributes,
            children: children.map { $0.clone() }
        ) as! Self
    }

    public func attribute(_ name: String) -> String? {
        attributes.first { $0.name.qualifiedName == name }?.value
    }

    public func elements(name: String) -> [XMLElement] {
        children.compactMap { $0 as? XMLElement }.filter { $0.name.name == name }
    }

    public func ensureNamespace(prefix: String? = nil, uri: XMLNamespaceURI) {
        if namespaceURI(for: prefix) == uri {
            return
        }
        namespaces.declare(prefix: prefix, uri: uri)
    }

    public override func namespaceURI(for prefix: String? = nil) -> XMLNamespaceURI? {
        namespaces.uri(for: prefix) ?? parent?.namespaceURI(for: prefix)
    }
}
