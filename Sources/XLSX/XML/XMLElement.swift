public final class XMLElement: XMLNode {
    public init(
        name: XMLName,
        attributes: [XMLAttribute] = [],
        children: [XMLNode] = []
    ) {
        self.name = name
        self.attributes = attributes
        self.childNodes = children
        super.init()
        for child in children {
            child.parent = self
        }
    }

    public var name: XMLName
    public var attributes: [XMLAttribute]
    public var childNodes: [XMLNode]

    public override var kind: XMLNodeKind {
        .element
    }

    public override var children: [XMLNode] {
        get { childNodes }
        set { childNodes = newValue }
    }
}
