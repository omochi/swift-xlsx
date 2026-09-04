public struct XLFrozenPanes: Sendable & Hashable {
    public init(rowCount: Int = 0, columnCount: Int = 0) {
        precondition(rowCount >= 0, "XLFrozenPanes rowCount must not be negative.")
        precondition(columnCount >= 0, "XLFrozenPanes columnCount must not be negative.")
        precondition(rowCount > 0 || columnCount > 0, "XLFrozenPanes must freeze at least one row or column.")
        precondition(rowCount < XLCellAddress.maxRowNumber, "XLFrozenPanes rowCount exceeds the worksheet limit.")
        precondition(
            columnCount < XLCellAddress.maxColumnNumber,
            "XLFrozenPanes columnCount exceeds the worksheet limit."
        )

        self.rowCount = rowCount
        self.columnCount = columnCount
    }

    public let rowCount: Int
    public let columnCount: Int
}
