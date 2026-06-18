import MemberwiseInit

@MemberwiseInit(.public)
public struct XMLAttribute: Sendable & Hashable {
    public var name: XMLName
    public var value: String
}
