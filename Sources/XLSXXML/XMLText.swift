public final class XMLText: XMLNode {
    public init(_ value: String) {
        self.value = value
        super.init()
    }

    public var value: String

    public override var kind: XMLNodeKind {
        .text
    }

    public override func clone() -> Self {
        XMLText(value) as! Self
    }
}
