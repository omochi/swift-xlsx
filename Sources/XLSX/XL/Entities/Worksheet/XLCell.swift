import MemberwiseInit

@MemberwiseInit(.public)
public struct XLCell {
    public var row: Int
    public var column: Int
    public var storage: XLCellStorage

    public var reference: XLCellReference {
        XLCellReference(row: row, column: column)
    }

    public var value: XLCellValue {
        get {
            storage.value
        }
        nonmutating set {
            storage.value = newValue
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
