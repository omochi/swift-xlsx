import MemberwiseInit

@MemberwiseInit(.public)
public struct XLCell {
    public var reference: XLCellReference
    public var storage: XLCellStorage

    public var value: XLCellValue {
        get {
            storage.value
        }
        nonmutating set {
            storage.value = newValue
        }
    }
}
