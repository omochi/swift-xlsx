import Foundation

public final class XMLDocument: XMLNode {
    public init(
        namespaces: XMLNamespaceTable = XMLNamespaceTable(),
        children: [XMLNode] = []
    ) {
        self.namespaces = namespaces
        self.childNodes = children
        super.init()
        for child in children {
            child.parent = self
        }
    }

    public var namespaces: XMLNamespaceTable
    public var childNodes: [XMLNode]

    public override var kind: XMLNodeKind {
        .document
    }

    public override var children: [XMLNode] {
        get { childNodes }
        set { childNodes = newValue }
    }

    public func kind(of node: XMLNode) -> XMLNodeKind {
        node.kind
    }

    public func data() -> Data {
        Data(xmlString.utf8)
    }

    public var xmlString: String {
        var serializer = XMLSerializer()
        return serializer.serialize(document: self)
    }

    public static func children(of node: XMLNode, in document: XMLDocument) -> [XMLNode] {
        node.children
    }

    public static func firstElement(named name: String, in document: XMLDocument) -> XMLElement? {
        firstElement(named: name, below: document, in: document)
    }

    public static func name(of node: XMLNode, in document: XMLDocument) -> String? {
        (node as? XMLElement)?.name.rawName
    }

    public static func attribute(
        _ name: String,
        of node: XMLNode,
        in document: XMLDocument
    ) -> String? {
        (node as? XMLElement)?.attributes.first { $0.name.rawName == name }?.value
    }

    private static func firstElement(
        named name: String,
        below node: XMLNode,
        in document: XMLDocument
    ) -> XMLElement? {
        for child in children(of: node, in: document) {
            if let element = child as? XMLElement, element.name.rawName == name {
                return element
            }
            if let match = firstElement(named: name, below: child, in: document) {
                return match
            }
        }
        return nil
    }
}
