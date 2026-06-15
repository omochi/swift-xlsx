import Foundation

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

    public override func clone() -> Self {
        let document = XMLDocument()
        for child in children {
            document.appendChild(child.clone())
        }
        return document as! Self
    }

    public var xmlString: String {
        var serializer = XMLSerializer()
        return serializer.serialize(document: self)
    }

}
