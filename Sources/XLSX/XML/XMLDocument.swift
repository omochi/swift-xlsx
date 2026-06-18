import Foundation
import SAXParser
import XMLCore

public final class XMLDocument: XMLNode {
    public init(
        children: [XMLNode] = []
    ) {
        self.childNodes = children
        super.init()
        for child in children {
            child._setParent(self)
        }
    }

    public init(data: Data) throws {
        var parser = SAXParser(handler: XMLDocumentBuilder())
        try parser.parse(bytes: Array(data).span)
        self.childNodes = parser.handler.document.children
        super.init()
        for child in childNodes {
            child._setParent(self)
        }
    }

    public convenience init(xmlString: String) throws {
        try self.init(data: Data(xmlString.utf8))
    }

    private var childNodes: [XMLNode]

    public override var kind: XMLNodeKind {
        .document
    }

    override var _children: [XMLNode] {
        get { childNodes }
        set { childNodes = newValue }
    }

    public override func clone() -> Self {
        let document = XMLDocument()
        for child in children {
            document.appendChild(child.clone())
        }
        return document as! Self
    }

    public func xmlString(pretty: Bool = false) -> String {
        let serializer = XMLSerializer(pretty: pretty)
        return serializer.serialize(document: self)
    }

    public var data: Data {
        Data(xmlString().utf8)
    }

    public func element(name: String) -> XMLElement? {
        children.compactMap { $0 as? XMLElement }.first { $0.name.name == name }
    }
}
