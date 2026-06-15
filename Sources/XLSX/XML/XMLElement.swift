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
    private var childNodes: [XMLNode]

    public override var kind: XMLNodeKind {
        .element
    }

    override var _children: [XMLNode] {
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

    public var xmlString: String {
        let serializer = XMLSerializer()
        return serializer.serialize(element: self)
    }

    public func attribute(name: String, namespaceURI: XMLNamespaceURI? = nil) -> String? {
        guard let index = attributeIndex(name: name, namespaceURI: namespaceURI) else {
            return nil
        }
        return attributes[index].value
    }

    @discardableResult
    public func setAttribute(
        name: String,
        namespaceURI: XMLNamespaceURI? = nil,
        value: String
    ) throws -> XMLAttribute {
        if let index = attributeIndex(name: name, namespaceURI: namespaceURI) {
            attributes[index].value = value
            return attributes[index]
        }

        let prefix: String?
        if let namespaceURI {
            guard let namespacePrefix = self.namespacePrefix(for: namespaceURI) else {
                throw XMLError.missingNamespacePrefix(namespaceURI.string)
            }
            prefix = namespacePrefix
        } else {
            prefix = nil
        }

        let attribute = XMLAttribute(
            name: XMLName(prefix: prefix, name: name),
            value: value
        )
        attributes.append(attribute)
        return attribute
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

    @discardableResult
    public func ensureNamespaceURI(prefix preferredPrefix: String, uri: XMLNamespaceURI) -> String {
        if let prefix = namespacePrefix(for: uri) {
            return prefix
        }

        var prefix = preferredPrefix
        var index = 2
        while namespaceURI(for: prefix) != nil {
            prefix = "\(preferredPrefix)\(index)"
            index += 1
        }
        namespaces.declare(prefix: prefix, uri: uri)
        return prefix
    }

    public override func namespaceURI(for prefix: String? = nil) -> XMLNamespaceURI? {
        namespaces.uri(for: prefix) ?? parent?.namespaceURI(for: prefix)
    }

    public func namespacePrefix(for uri: XMLNamespaceURI) -> String? {
        for declaration in namespaces.declarations where declaration.uri == uri {
            if let prefix = declaration.prefix {
                return prefix
            }
        }
        return (parent as? XMLElement)?.namespacePrefix(for: uri)
    }

    private func namespaceURI(forAttribute name: XMLName) -> XMLNamespaceURI? {
        guard let prefix = name.prefix else {
            return nil
        }
        return namespaceURI(for: prefix)
    }

    private func attributeIndex(name: String, namespaceURI: XMLNamespaceURI?) -> Int? {
        attributes.firstIndex { attribute in
            attribute.name.name == name
                && self.namespaceURI(forAttribute: attribute.name) == namespaceURI
        }
    }
}
