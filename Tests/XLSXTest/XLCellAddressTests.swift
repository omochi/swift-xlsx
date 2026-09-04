import Testing
import XLSX

@Suite
struct XLCellAddressTests {
    @Test func providesSpreadsheetLimits() {
        #expect(XLCellAddress.maxRowNumber == 1_048_576)
        #expect(XLCellAddress.maxColumnNumber == 16_384)
        #expect(
            XLCellAddress(
                row: XLCellAddress.maxRowNumber,
                column: XLCellAddress.maxColumnNumber
            ).description == "XFD1048576"
        )
    }

    @Test func describesAddressInA1Notation() {
        #expect(XLCellAddress(row: 1, column: 1).description == "A1")
        #expect(XLCellAddress(row: 10, column: 3).description == "C10")
        #expect(XLCellAddress(row: 1, column: 26).description == "Z1")
        #expect(XLCellAddress(row: 1, column: 27).description == "AA1")
        #expect(XLCellAddress(row: 1048576, column: 16384).description == "XFD1048576")
        #expect(XLCellAddress(isRowAbsolute: true, row: 1, isColumnAbsolute: false, column: 1).description == "A$1")
        #expect(XLCellAddress(isRowAbsolute: false, row: 1, isColumnAbsolute: true, column: 1).description == "$A1")
        #expect(XLCellAddress(isRowAbsolute: true, row: 1, isColumnAbsolute: true, column: 1).description == "$A$1")
    }

    @Test func parsesA1Notation() throws {
        #expect(XLCellAddress("A1") == XLCellAddress(row: 1, column: 1))
        #expect(XLCellAddress("C10") == XLCellAddress(row: 10, column: 3))
        #expect(XLCellAddress("Z1") == XLCellAddress(row: 1, column: 26))
        #expect(XLCellAddress("AA1") == XLCellAddress(row: 1, column: 27))
        #expect(XLCellAddress("XFD1048576") == XLCellAddress(row: 1048576, column: 16384))
        #expect(XLCellAddress("A$1") == XLCellAddress(isRowAbsolute: true, row: 1, isColumnAbsolute: false, column: 1))
        #expect(XLCellAddress("$A1") == XLCellAddress(isRowAbsolute: false, row: 1, isColumnAbsolute: true, column: 1))
        #expect(XLCellAddress("$A$1") == XLCellAddress(isRowAbsolute: true, row: 1, isColumnAbsolute: true, column: 1))
    }

    @Test func parsesLowercaseColumnLetters() {
        #expect(XLCellAddress("c10") == XLCellAddress(row: 10, column: 3))
        #expect(XLCellAddress("$c$10") == XLCellAddress(isRowAbsolute: true, row: 10, isColumnAbsolute: true, column: 3))
    }

    @Test func describesColumnStrings() {
        #expect(XLCellAddress.columnString(1) == "A")
        #expect(XLCellAddress.columnString(26) == "Z")
        #expect(XLCellAddress.columnString(27) == "AA")
        #expect(XLCellAddress.columnString(16384) == "XFD")
    }

    @Test func parsesColumnStrings() {
        #expect(XLCellAddress.columnValue(string: "A") == 1)
        #expect(XLCellAddress.columnValue(string: "Z") == 26)
        #expect(XLCellAddress.columnValue(string: "AA") == 27)
        #expect(XLCellAddress.columnValue(string: "xfd") == 16384)
        #expect(XLCellAddress.columnValue(string: "") == nil)
        #expect(XLCellAddress.columnValue(string: "A1") == nil)
    }

    @Test func rejectsInvalidAddresses() {
        #expect(XLCellAddress("") == nil)
        #expect(XLCellAddress("A") == nil)
        #expect(XLCellAddress("1") == nil)
        #expect(XLCellAddress("A0") == nil)
        #expect(XLCellAddress("A-1") == nil)
        #expect(XLCellAddress("1A") == nil)
        #expect(XLCellAddress("A1:B2") == nil)
        #expect(XLCellAddress("$") == nil)
        #expect(XLCellAddress("$1") == nil)
        #expect(XLCellAddress("A$") == nil)
        #expect(XLCellAddress("$$A1") == nil)
        #expect(XLCellAddress("$A$$1") == nil)
    }
}
