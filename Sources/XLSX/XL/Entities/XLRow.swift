import MemberwiseInit

@MemberwiseInit(.public)
public struct XLRow {
    public var number: Int
    public var storage: XLRowStorage

    public var maxColumnNumber: Int? {
        storage.maxColumnNumber
    }

    public var existingColumnNumbers: [Int] {
        storage.existingColumnNumbers
    }

    public func cell(column: Int) -> XLCell {
        XLCell(
            row: number,
            column: column,
            storage: storage.cell(column: column)
        )
    }

    public func existingCell(column: Int) -> XLCell? {
        guard let cellStorage = storage.existingCell(column: column) else {
            return nil
        }

        return XLCell(
            row: number,
            column: column,
            storage: cellStorage
        )
    }
}
