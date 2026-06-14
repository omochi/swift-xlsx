import MemberwiseInit

@MemberwiseInit(.public)
public struct OPCPackageNodeID: Sendable & Hashable {
    public var rawValue: Int
}
