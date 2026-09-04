import MemberwiseInit

@MemberwiseInit(.public)
public struct XLSheetCellRangeAddress: Sendable & Hashable & LosslessStringConvertible {
    public init?(_ description: String) {
        guard let separatorIndex = XLSheetCellAddress.sheetCellSeparatorIndex(in: description) else {
            return nil
        }

        let sheetNameText = String(description[..<separatorIndex])
        let cellRangeAddressText = String(description[description.index(after: separatorIndex)...])
        guard !cellRangeAddressText.isEmpty,
              let sheetName = XLSheetCellAddress.parseSheetName(sheetNameText),
              let cellRangeAddress = XLCellRangeAddress(cellRangeAddressText)
        else {
            return nil
        }

        self.sheetName = sheetName
        self.cellRangeAddress = cellRangeAddress
    }

    public var sheetName: String
    public var cellRangeAddress: XLCellRangeAddress

    public var description: String {
        XLSheetCellAddress.description(sheetName: sheetName) + "!" + cellRangeAddress.description
    }
}
