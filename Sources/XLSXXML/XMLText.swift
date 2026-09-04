import Foundation

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

    public func xmlString() -> String {
        value
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
    }

    public func data() -> Data {
        Data(xmlString().utf8)
    }
}
