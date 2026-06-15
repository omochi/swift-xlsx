import MemberwiseInit

@MemberwiseInit(.public)
public struct XMLAttribute: Sendable {
    public var name: XMLName
    public var value: String
}
