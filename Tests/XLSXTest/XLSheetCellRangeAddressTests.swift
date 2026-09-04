import Testing
import XLSX

@Suite
struct XLSheetCellRangeAddressTests {
    @Test func describesSheetCellRangeAddress() {
        #expect(
            XLSheetCellRangeAddress(
                sheetName: "Sheet",
                cellRangeAddress: XLCellRangeAddress(start: .init(row: 1, column: 1), last: .init(row: 3, column: 2))
            ).description == "Sheet!A1:B3"
        )
        #expect(
            XLSheetCellRangeAddress(
                sheetName: "Sheet 1",
                cellRangeAddress: XLCellRangeAddress(start: .init(row: 1, column: 1), last: .init(row: 1, column: 1))
            ).description == "'Sheet 1'!A1"
        )
        #expect(
            XLSheetCellRangeAddress(
                sheetName: "John's",
                cellRangeAddress: XLCellRangeAddress(
                    start: .init(isRowAbsolute: true, row: 1, isColumnAbsolute: true, column: 3),
                    last: .init(isRowAbsolute: true, row: 2, isColumnAbsolute: true, column: 3)
                )
            ).description == "'John''s'!$C$1:$C$2"
        )
    }

    @Test func parsesSheetCellRangeAddress() {
        #expect(
            XLSheetCellRangeAddress("Sheet!A1:B3") == XLSheetCellRangeAddress(
                sheetName: "Sheet",
                cellRangeAddress: XLCellRangeAddress(start: .init(row: 1, column: 1), last: .init(row: 3, column: 2))
            )
        )
        #expect(
            XLSheetCellRangeAddress("'Sheet 1'!A1") == XLSheetCellRangeAddress(
                sheetName: "Sheet 1",
                cellRangeAddress: XLCellRangeAddress(start: .init(row: 1, column: 1), last: .init(row: 1, column: 1))
            )
        )
        #expect(
            XLSheetCellRangeAddress("'John''s'!$C$1:$C$2") == XLSheetCellRangeAddress(
                sheetName: "John's",
                cellRangeAddress: XLCellRangeAddress(
                    start: .init(isRowAbsolute: true, row: 1, isColumnAbsolute: true, column: 3),
                    last: .init(isRowAbsolute: true, row: 2, isColumnAbsolute: true, column: 3)
                )
            )
        )
    }

    @Test func rejectsInvalidSheetCellRangeAddresses() {
        #expect(XLSheetCellRangeAddress("") == nil)
        #expect(XLSheetCellRangeAddress("Sheet") == nil)
        #expect(XLSheetCellRangeAddress("!A1:B2") == nil)
        #expect(XLSheetCellRangeAddress("Sheet!") == nil)
        #expect(XLSheetCellRangeAddress("Sheet!A1:") == nil)
        #expect(XLSheetCellRangeAddress("Sheet!:B2") == nil)
        #expect(XLSheetCellRangeAddress("'Sheet!A1:B2") == nil)
        #expect(XLSheetCellRangeAddress("Sheet'!A1:B2") == nil)
    }
}
