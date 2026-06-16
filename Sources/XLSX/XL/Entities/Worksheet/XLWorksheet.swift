import MemberwiseInit

@MemberwiseInit(.public)
public struct XLWorksheet {
    public var package: XLDocumentPackage
    public var sheetID: Int
    public var file: XLWorksheetFile

    public var name: String {
        get {
            package.workbook.file.sheets[sheetIndex].name
        }
        nonmutating set {
            package.workbook.file.sheets[sheetIndex].name = newValue
        }
    }

    public var maxRowNumber: Int? {
        file.maxRowNumber
    }

    public var existingRowNumbers: [Int] {
        file.existingRowNumbers
    }

    public func row(_ number: Int) -> XLRow {
        XLRow(
            number: number,
            storage: file.row(number)
        )
    }

    public func existingRow(_ number: Int) -> XLRow? {
        guard let storage = file.existingRow(number) else {
            return nil
        }

        return XLRow(
            number: number,
            storage: storage
        )
    }

    public func cell(row: Int, column: Int) -> XLCell {
        self.row(row).cell(column: column)
    }

    public func existingCell(row: Int, column: Int) -> XLCell? {
        existingRow(row)?.existingCell(column: column)
    }

    public func cell(address: XLCellAddress) -> XLCell {
        cell(row: address.row, column: address.column)
    }

    public func existingCell(address: XLCellAddress) -> XLCell? {
        existingCell(row: address.row, column: address.column)
    }

    private var sheetIndex: Int {
        guard let index = package.workbook.file.sheets.firstIndex(where: { $0.sheetID == sheetID }) else {
            preconditionFailure("Missing sheet for sheetID \(sheetID)")
        }
        return index
    }
}
