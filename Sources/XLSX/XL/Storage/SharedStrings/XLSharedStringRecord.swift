import MemberwiseInit

@MemberwiseInit(.public)
public struct XLSharedStringRecord {
    public var index: Int
    public var childIndex: Int?
    public var item: XLSharedStringItem?
    public var element: XMLElement
}
