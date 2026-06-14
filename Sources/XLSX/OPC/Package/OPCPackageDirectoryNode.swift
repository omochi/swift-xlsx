import MemberwiseInit

@MemberwiseInit(.public)
public struct OPCPackageDirectoryNode: Sendable {
    public var entryDictionary: [String: OPCPackageNodeID] = [:]

    public var children: [(String, OPCPackageNodeID)] {
        entryDictionary.sorted(by: { $0.key < $1.key })
    }
}
