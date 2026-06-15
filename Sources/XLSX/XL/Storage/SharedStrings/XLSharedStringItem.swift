import MemberwiseInit

@MemberwiseInit(.public)
public struct XLSharedStringItem: Sendable & Hashable {
    public var text: String
}
