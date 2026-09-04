import Testing
import XLSX

@Suite
struct XLSheetCellAddressTests {
    @Test func describesSheetCellAddress() {
        #expect(XLSheetCellAddress(sheetName: "Sheet", cellAddress: .init(row: 1, column: 1)).description == "Sheet!A1")
        #expect(XLSheetCellAddress(sheetName: "Sheet_1", cellAddress: .init(row: 10, column: 3)).description == "Sheet_1!C10")
        #expect(XLSheetCellAddress(sheetName: "Sheet 1", cellAddress: .init(row: 1, column: 1)).description == "'Sheet 1'!A1")
        #expect(XLSheetCellAddress(sheetName: "John's", cellAddress: .init(row: 2, column: 2)).description == "'John''s'!B2")
    }

    @Test func parsesSheetCellAddress() {
        #expect(XLSheetCellAddress("Sheet!A1") == XLSheetCellAddress(sheetName: "Sheet", cellAddress: .init(row: 1, column: 1)))
        #expect(XLSheetCellAddress("Sheet_1!C10") == XLSheetCellAddress(sheetName: "Sheet_1", cellAddress: .init(row: 10, column: 3)))
        #expect(XLSheetCellAddress("'Sheet 1'!A1") == XLSheetCellAddress(sheetName: "Sheet 1", cellAddress: .init(row: 1, column: 1)))
        #expect(XLSheetCellAddress("'John''s'!B2") == XLSheetCellAddress(sheetName: "John's", cellAddress: .init(row: 2, column: 2)))
    }

    @Test func rejectsInvalidSheetCellAddresses() {
        #expect(XLSheetCellAddress("") == nil)
        #expect(XLSheetCellAddress("Sheet") == nil)
        #expect(XLSheetCellAddress("!A1") == nil)
        #expect(XLSheetCellAddress("Sheet!") == nil)
        #expect(XLSheetCellAddress("Sheet!A0") == nil)
        #expect(XLSheetCellAddress("'Sheet!A1") == nil)
        #expect(XLSheetCellAddress("'Sheet' A1") == nil)
        #expect(XLSheetCellAddress("Sheet'!A1") == nil)
        #expect(XLSheetCellAddress("'John's'!A1") == nil)
    }
}
