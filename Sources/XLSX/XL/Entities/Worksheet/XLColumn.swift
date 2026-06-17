import MemberwiseInit

@MemberwiseInit(.public)
public struct XLColumn {
    public var number: Int
    public var storage: XLColumnStorage

    public var width: Double? {
        get {
            storage.width
        }
        nonmutating set {
            storage.width = newValue
        }
    }

    public var format: XLCellFormat? {
        get {
            storage.format
        }
        nonmutating set {
            storage.format = newValue
        }
    }
}
