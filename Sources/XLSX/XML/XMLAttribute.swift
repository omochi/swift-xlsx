import MemberwiseInit

@MemberwiseInit(.public)
public struct XMLAttribute: Sendable {
    public var name: XMLName
    public var value: String

    public var isNamespaceDeclaration: Bool {
        name.rawName == "xmlns" || name.rawName.hasPrefix("xmlns:")
    }
}
