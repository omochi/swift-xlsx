import MemberwiseInit

@MemberwiseInit(.public)
public struct OPCRelationship: Sendable {
    public var id: String
    public var type: String
    public var target: String
}
