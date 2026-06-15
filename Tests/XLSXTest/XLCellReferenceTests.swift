import Testing
import XLSX

@Suite
struct XLCellReferenceTests {
    @Test func describesReferenceInA1Notation() {
        #expect(XLCellReference(row: 1, column: 1).description == "A1")
        #expect(XLCellReference(row: 10, column: 3).description == "C10")
        #expect(XLCellReference(row: 1, column: 26).description == "Z1")
        #expect(XLCellReference(row: 1, column: 27).description == "AA1")
        #expect(XLCellReference(row: 1048576, column: 16384).description == "XFD1048576")
    }

    @Test func parsesA1Notation() throws {
        #expect(XLCellReference("A1") == XLCellReference(row: 1, column: 1))
        #expect(XLCellReference("C10") == XLCellReference(row: 10, column: 3))
        #expect(XLCellReference("Z1") == XLCellReference(row: 1, column: 26))
        #expect(XLCellReference("AA1") == XLCellReference(row: 1, column: 27))
        #expect(XLCellReference("XFD1048576") == XLCellReference(row: 1048576, column: 16384))
    }

    @Test func parsesLowercaseColumnLetters() {
        #expect(XLCellReference("c10") == XLCellReference(row: 10, column: 3))
    }

    @Test func rejectsInvalidReferences() {
        #expect(XLCellReference("") == nil)
        #expect(XLCellReference("A") == nil)
        #expect(XLCellReference("1") == nil)
        #expect(XLCellReference("A0") == nil)
        #expect(XLCellReference("A-1") == nil)
        #expect(XLCellReference("1A") == nil)
        #expect(XLCellReference("A1:B2") == nil)
    }
}
