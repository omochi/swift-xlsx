import MemberwiseInit

@MemberwiseInit(.public)
public struct XMLName: Sendable & Hashable {
    public var prefix: String? = nil
    public var name: String

    public var qualifiedName: String {
        guard let prefix else {
            return name
        }
        return "\(prefix):\(name)"
    }
}
