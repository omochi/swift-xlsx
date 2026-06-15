import Foundation
import Testing
import XLSX

@Suite
struct XLWorksheetFileTests {
    @Test func readsSparseRowsAndCellsFromWorksheetXML() throws {
        let worksheet = try XLWorksheetFile(data: Data("""
            <worksheet xmlns="\(XMLNamespaceURI.spreadsheet.string)">
              <sheetData>
                <row r="2">
                  <c r="B2"><v>left</v></c>
                  <c r="D2"><v>right</v></c>
                </row>
                <row r="10">
                  <c r="C10"><v>bottom</v></c>
                </row>
              </sheetData>
            </worksheet>
            """.utf8))

        #expect(worksheet.rowByNumber == [
            2: XLRowStorage(cellByColumn: [
                2: XLCellStorage(value: XLCellValue(rawValue: "left")),
                4: XLCellStorage(value: XLCellValue(rawValue: "right")),
            ]),
            10: XLRowStorage(cellByColumn: [
                3: XLCellStorage(value: XLCellValue(rawValue: "bottom")),
            ]),
        ])
    }

    @Test func writesSparseRowsAndCellsToWorksheetXML() throws {
        let worksheet = XLWorksheetFile(rowByNumber: [
            10: XLRowStorage(cellByColumn: [
                3: XLCellStorage(value: XLCellValue(rawValue: "bottom")),
            ]),
            2: XLRowStorage(cellByColumn: [
                4: XLCellStorage(value: XLCellValue(rawValue: "right")),
                2: XLCellStorage(value: XLCellValue(rawValue: "left")),
            ]),
        ])

        let xml = try String(decoding: worksheet.data(), as: UTF8.self)

        #expect(xml.contains(#"<sheetData><row r="2"><c r="B2"><v>left</v></c><c r="D2"><v>right</v></c></row><row r="10"><c r="C10"><v>bottom</v></c></row></sheetData>"#))
    }

    @Test func writesRowsSortedBeforeOtherSheetDataChildren() throws {
        let worksheet = try XLWorksheetFile(data: Data("""
            <worksheet xmlns="\(XMLNamespaceURI.spreadsheet.string)">
              <sheetData>
                <row r="10">
                  <c r="C10"><v>bottom</v></c>
                </row>
                <marker/>
                <row r="2">
                  <c r="B2"><v>left</v></c>
                </row>
              </sheetData>
            </worksheet>
            """.utf8))

        worksheet.cell(row: 5, column: 1).value = XLCellValue(rawValue: "middle")

        let xml = try String(decoding: worksheet.data(), as: UTF8.self)

        let row2Range = try #require(xml.range(of: #"<row r="2""#))
        let row5Range = try #require(xml.range(of: #"<row r="5""#))
        let row10Range = try #require(xml.range(of: #"<row r="10""#))
        let markerRange = try #require(xml.range(of: #"<marker/>"#))

        #expect(row2Range.lowerBound < row5Range.lowerBound)
        #expect(row5Range.lowerBound < row10Range.lowerBound)
        #expect(row10Range.lowerBound < markerRange.lowerBound)
    }

    @Test func writesCellsSortedBeforeOtherRowChildren() throws {
        let worksheet = try XLWorksheetFile(data: Data("""
            <worksheet xmlns="\(XMLNamespaceURI.spreadsheet.string)">
              <sheetData>
                <row r="2">
                  <c r="D2"><v>right</v></c>
                  <marker/>
                  <c r="B2"><v>left</v></c>
                </row>
              </sheetData>
            </worksheet>
            """.utf8))

        worksheet.cell(row: 2, column: 3).value = XLCellValue(rawValue: "middle")

        let xml = try String(decoding: worksheet.data(), as: UTF8.self)

        let cellBRange = try #require(xml.range(of: #"<c r="B2""#))
        let cellCRange = try #require(xml.range(of: #"<c r="C2""#))
        let cellDRange = try #require(xml.range(of: #"<c r="D2""#))
        let markerRange = try #require(xml.range(of: #"<marker/>"#))

        #expect(cellBRange.lowerBound < cellCRange.lowerBound)
        #expect(cellCRange.lowerBound < cellDRange.lowerBound)
        #expect(cellDRange.lowerBound < markerRange.lowerBound)
    }

    @Test func exposesExistingRowNumbersAndMaxRowNumber() {
        let worksheet = XLWorksheetFile(rowByNumber: [
            10: XLRowStorage(cellByColumn: [:]),
            2: XLRowStorage(cellByColumn: [:]),
        ])

        #expect(worksheet.maxRowNumber == 10)
        #expect(worksheet.existingRowNumbers == [2, 10])
    }

    @Test func returnsExistingRowsWithoutCreatingMissingRows() {
        let worksheet = XLWorksheetFile(rowByNumber: [
            2: XLRowStorage(cellByColumn: [
                1: XLCellStorage(value: XLCellValue(rawValue: "left")),
            ]),
        ])

        #expect(worksheet.existingRow(2) == XLRowStorage(cellByColumn: [
            1: XLCellStorage(value: XLCellValue(rawValue: "left")),
        ]))
        #expect(worksheet.existingRow(3) == nil)
        #expect(worksheet.existingRowNumbers == [2])
    }

    @Test func createsMissingRowsWhenAccessed() {
        let worksheet = XLWorksheetFile()

        #expect(worksheet.maxRowNumber == nil)
        #expect(worksheet.existingRow(3) == nil)

        #expect(worksheet.row(3) == XLRowStorage(cellByColumn: [:]))
        #expect(worksheet.existingRow(3) == XLRowStorage(cellByColumn: [:]))
        #expect(worksheet.maxRowNumber == 3)
        #expect(worksheet.existingRowNumbers == [3])
    }

    @Test func editsCellsThroughAccessedRow() {
        let worksheet = XLWorksheetFile()

        worksheet.row(3).cell(column: 2).value = XLCellValue(rawValue: "value")

        #expect(worksheet.existingRow(3)?.cellByColumn[2]?.value == XLCellValue(rawValue: "value"))
    }

    @Test func editsCellsThroughWorksheetCellAccessors() throws {
        let worksheet = XLWorksheetFile()

        worksheet.cell(row: 3, column: 2).value = XLCellValue(rawValue: "left")
        worksheet.cell(reference: try #require(XLCellReference("D4"))).value = XLCellValue(rawValue: "right")

        #expect(worksheet.existingRow(3)?.existingCell(column: 2)?.value == XLCellValue(rawValue: "left"))
        #expect(worksheet.existingRow(4)?.existingCell(column: 4)?.value == XLCellValue(rawValue: "right"))
    }

    @Test func exposesExistingColumnNumbersAndMaxColumnNumber() {
        let row = XLRowStorage(cellByColumn: [
            4: XLCellStorage(value: XLCellValue(rawValue: "right")),
            2: XLCellStorage(value: XLCellValue(rawValue: "left")),
        ])

        #expect(row.maxColumnNumber == 4)
        #expect(row.existingColumnNumbers == [2, 4])
    }

    @Test func returnsExistingCellsWithoutCreatingMissingCells() {
        let row = XLRowStorage(cellByColumn: [
            2: XLCellStorage(value: XLCellValue(rawValue: "left")),
        ])

        #expect(row.existingCell(column: 2) == XLCellStorage(value: XLCellValue(rawValue: "left")))
        #expect(row.existingCell(column: 3) == nil)
        #expect(row.existingColumnNumbers == [2])
    }

    @Test func createsMissingCellsWhenAccessed() {
        let row = XLRowStorage(cellByColumn: [:])

        #expect(row.maxColumnNumber == nil)
        #expect(row.existingCell(column: 3) == nil)

        #expect(row.cell(column: 3) == XLCellStorage(value: XLCellValue(rawValue: "")))
        #expect(row.existingCell(column: 3) == XLCellStorage(value: XLCellValue(rawValue: "")))
        #expect(row.maxColumnNumber == 3)
        #expect(row.existingColumnNumbers == [3])
    }

    @Test func patchesKnownCellsWithoutRemovingUnknownCellAttributes() throws {
        let worksheet = try XLWorksheetFile(data: Data("""
            <worksheet xmlns="\(XMLNamespaceURI.spreadsheet.string)">
              <sheetData>
                <row r="1" custom="keep">
                  <c r="A1" t="s"><v>0</v></c>
                </row>
              </sheetData>
            </worksheet>
            """.utf8))
        worksheet.rowByNumber[1]?.cellByColumn[1]?.value = XLCellValue(rawValue: "1")

        let xml = try String(decoding: worksheet.data(), as: UTF8.self)

        #expect(xml.contains(#"<row r="1" custom="keep">"#))
        #expect(xml.contains(#"<c r="A1" t="s"><v>1</v></c>"#))
    }
}
