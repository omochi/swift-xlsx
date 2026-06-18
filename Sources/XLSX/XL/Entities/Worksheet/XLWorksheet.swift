import MemberwiseInit

@MemberwiseInit(.public)
public struct XLWorksheet {
    public let package: XLDocumentPackage
    public let sheetID: Int
    public let file: XLWorksheetFile

    public var name: String {
        get {
            package.workbook.file.sheets[sheetIndex].name
        }
        nonmutating set {
            package.workbook.file.sheets[sheetIndex].name = newValue
        }
    }

    public var maxColumnNumber: Int? {
        file.maxColumnNumber
    }

    public var maxRowNumber: Int? {
        file.maxRowNumber
    }

    public var existingColumnNumbers: [Int] {
        file.existingColumnNumbers
    }

    public var existingRowNumbers: [Int] {
        file.existingRowNumbers
    }

    public var existingColumns: [XLColumn] {
        file.existingColumnsWithNumber.map { columnNumber, storage in
            XLColumn(
                number: columnNumber,
                storage: storage
            )
        }
    }

    public var existingRows: [XLRow] {
        file.existingRowsWithNumber.map { rowNumber, storage in
            XLRow(
                number: rowNumber,
                storage: storage
            )
        }
    }

    public func existingColumn(_ number: Int) -> XLColumn? {
        guard let storage = file.existingColumn(number) else {
            return nil
        }

        return XLColumn(
            number: number,
            storage: storage
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

    public func column(_ number: Int) -> XLColumn {
        XLColumn(
            number: number,
            storage: file.column(number)
        )
    }

    public func row(_ number: Int) -> XLRow {
        XLRow(
            number: number,
            storage: file.row(number)
        )
    }

    public func existingCell(row: Int, column: Int) -> XLCell? {
        existingRow(row)?.existingCell(column: column)
    }

    public func cell(row: Int, column: Int) -> XLCell {
        self.row(row).cell(column: column)
    }

    public func existingCell(address: XLCellAddress) -> XLCell? {
        existingCell(row: address.row, column: address.column)
    }

    public func cell(address: XLCellAddress) -> XLCell {
        cell(row: address.row, column: address.column)
    }

    private var sheetIndex: Int {
        guard let index = package.workbook.file.sheets.firstIndex(where: { $0.sheetID == sheetID }) else {
            preconditionFailure("Missing sheet for sheetID \(sheetID)")
        }
        return index
    }
}
