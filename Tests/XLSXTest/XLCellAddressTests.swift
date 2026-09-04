import Testing
import XLSX

@Suite
struct XLCellAddressTests {
    @Test func describesAddressInA1Notation() {
        #expect(XLCellAddress(row: 1, column: 1).description == "A1")
        #expect(XLCellAddress(row: 10, column: 3).description == "C10")
        #expect(XLCellAddress(row: 1, column: 26).description == "Z1")
        #expect(XLCellAddress(row: 1, column: 27).description == "AA1")
        #expect(XLCellAddress(row: 1048576, column: 16384).description == "XFD1048576")
    }

    @Test func parsesA1Notation() throws {
        #expect(XLCellAddress("A1") == XLCellAddress(row: 1, column: 1))
        #expect(XLCellAddress("C10") == XLCellAddress(row: 10, column: 3))
        #expect(XLCellAddress("Z1") == XLCellAddress(row: 1, column: 26))
        #expect(XLCellAddress("AA1") == XLCellAddress(row: 1, column: 27))
        #expect(XLCellAddress("XFD1048576") == XLCellAddress(row: 1048576, column: 16384))
    }

    @Test func parsesLowercaseColumnLetters() {
        #expect(XLCellAddress("c10") == XLCellAddress(row: 10, column: 3))
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
    }
}
