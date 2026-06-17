import Foundation
import Testing
import XLSX

@Suite
struct XLWorksheetFileTests {
    @Test func readsSparseRowsAndCellsFromWorksheetXML() throws {
        let worksheet = try worksheetFile(data: Data("""
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

        #expect(worksheet.existingRowNumbers == [2, 10])
        #expect(worksheet.existingRow(2)?.existingColumnNumbers == [2, 4])
        #expect(worksheet.existingRow(2)?.existingCell(column: 2)?.value == .string("left"))
        #expect(worksheet.existingRow(2)?.existingCell(column: 4)?.value == .string("right"))
        #expect(worksheet.existingRow(10)?.existingColumnNumbers == [3])
        #expect(worksheet.existingRow(10)?.existingCell(column: 3)?.value == .string("bottom"))
    }

    @Test func readsCellValueTypesFromWorksheetXML() throws {
        let worksheet = try worksheetFile(data: Data("""
            <worksheet xmlns="\(XMLNamespaceURI.spreadsheet.string)">
              <sheetData>
                <row r="1">
                  <c r="A1"><v>42</v></c>
                  <c r="B1" t="n"><v>3.14</v></c>
                  <c r="C1" t="b"><v>1</v></c>
                  <c r="D1" t="e"><v>#DIV/0!</v></c>
                  <c r="E1" t="d"><v>2026-06-16T09:30:00Z</v></c>
                  <c r="F1" t="inlineStr"><is><t>inline</t></is></c>
                  <c r="G1" t="str"><f>TEXT(1,"0")</f><v>cached</v></c>
                  <c r="H1" t="s"><v>5</v></c>
                  <c r="I1" t="b"><v>0</v></c>
                  <c r="J1" t="b"><v>-2</v></c>
                  <c r="K1" t="b"><v>Yes</v></c>
                  <c r="L1" t="b"><v>FALSE</v></c>
                  <c r="M1"><v>45292.5</v></c>
                </row>
              </sheetData>
            </worksheet>
            """.utf8))

        #expect(worksheet.existingRow(1)?.existingCell(column: 1)?.value == .number("42"))
        #expect(worksheet.existingRow(1)?.existingCell(column: 2)?.value == .number("3.14"))
        #expect(worksheet.existingRow(1)?.existingCell(column: 3)?.value == .boolean(true))
        #expect(worksheet.existingRow(1)?.existingCell(column: 4)?.value == .error("#DIV/0!"))
        #expect(worksheet.existingRow(1)?.existingCell(column: 5)?.value == .string("2026-06-16T09:30:00Z"))
        #expect(worksheet.existingRow(1)?.existingCell(column: 6)?.value == .string("inline"))
        #expect(worksheet.existingRow(1)?.existingCell(column: 7)?.value == .string("cached"))
        #expect(worksheet.existingRow(1)?.existingCell(column: 8) == nil)
        #expect(worksheet.existingRow(1)?.existingCell(column: 9)?.value == .boolean(false))
        #expect(worksheet.existingRow(1)?.existingCell(column: 10)?.value == .boolean(true))
        #expect(worksheet.existingRow(1)?.existingCell(column: 11)?.value == .boolean(true))
        #expect(worksheet.existingRow(1)?.existingCell(column: 12)?.value == .boolean(false))
        #expect(worksheet.existingRow(1)?.existingCell(column: 13)?.value == .number("45292.5"))
    }

    @Test func ignoresStandaloneWorksheetCellFormatWithoutStyles() throws {
        let worksheet = try worksheetFile(data: Data("""
            <worksheet xmlns="\(XMLNamespaceURI.spreadsheet.string)">
              <sheetData>
                <row r="1">
                  <c r="A1" s="2"><v>42</v></c>
                  <c r="B1" t="s" s="3"><v>0</v></c>
                </row>
              </sheetData>
            </worksheet>
            """.utf8))

        #expect(worksheet.existingRow(1)?.existingCell(column: 1)?.format == nil)
        #expect(worksheet.existingRow(1)?.existingCell(column: 2) == nil)
    }

    @Test func writesSparseRowsAndCellsToWorksheetXML() throws {
        let worksheet = XLWorksheetFile(rowByNumber: [
            10: XLRowStorage(cellByColumn: [
                3: XLCellStorage(value: .string("bottom")),
            ]),
            2: XLRowStorage(cellByColumn: [
                4: XLCellStorage(value: .string("right")),
                2: XLCellStorage(value: .string("left")),
            ]),
        ])

        let xml = try String(decoding: worksheet.xmlDocument().data, as: UTF8.self)

        #expect(xml.contains(#"<sheetData><row r="2"><c r="B2"><v>left</v></c><c r="D2"><v>right</v></c></row><row r="10"><c r="C10"><v>bottom</v></c></row></sheetData>"#))
    }

    @Test func writesCellValueTypesToWorksheetXML() throws {
        let worksheet = XLWorksheetFile(rowByNumber: [
            1: XLRowStorage(cellByColumn: [
                1: XLCellStorage(value: .number("42")),
                2: XLCellStorage(value: .boolean(false)),
                3: XLCellStorage(value: .error("#N/A")),
            ]),
        ])

        let xml = try String(decoding: worksheet.xmlDocument().data, as: UTF8.self)

        #expect(xml.contains(#"<c r="A1"><v>42</v></c>"#))
        #expect(xml.contains(#"<c r="B1" t="b"><v>0</v></c>"#))
        #expect(xml.contains(#"<c r="C1" t="e"><v>#N/A</v></c>"#))
    }

    @Test func removesCellFormatWhenStandaloneWorksheetHasNoWritePlan() throws {
        let format = XLCellFormat(numberFormatID: 14, applyNumberFormat: true)
        let formattedCell = XLCellStorage(value: .number("42"), format: format)
        let worksheet = XLWorksheetFile(rowByNumber: [
            1: XLRowStorage(cellByColumn: [
                1: formattedCell,
            ]),
        ])

        let xml = try String(decoding: worksheet.xmlDocument().data, as: UTF8.self)

        #expect(xml.contains(#"<c r="A1"><v>42</v></c>"#))
    }

    @Test func writesStringCellsToSharedStringsWhenSavingDocument() throws {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("swift-xlsx-tests-\(UUID().uuidString)")
            .appendingPathExtension("xlsx")
        defer {
            try? FileManager.default.removeItem(at: url)
        }

        let document = XLDocument()
        let worksheet = try #require(document.workbook.worksheets.first)
        worksheet.cell(row: 1, column: 1).value = .string("shared")
        try document.save(to: url)

        #expect(worksheet.existingRow(1)?.existingCell(column: 1)?.value == .string("shared"))
        #expect(document.package.sharedStrings.file.records.records == [])

        let package = try OPCPackage(data: Data(contentsOf: url))
        let worksheetXML = try String(
            decoding: #require(package.data(at: OPCFilePath(string: "/xl/worksheets/sheet1.xml"))),
            as: UTF8.self
        )
        let sharedStringsXML = try String(
            decoding: #require(package.data(at: OPCFilePath(string: "/xl/sharedStrings.xml"))),
            as: UTF8.self
        )

        #expect(worksheetXML.contains(#"<c r="A1" t="s"><v>0</v></c>"#))
        #expect(sharedStringsXML.contains(#"<t>shared</t>"#))
    }

    @Test func writesRowsSortedBeforeOtherSheetDataChildren() throws {
        let worksheet = try worksheetFile(data: Data("""
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

        worksheet.cell(row: 5, column: 1).value = .string("middle")

        let xml = try String(decoding: worksheet.xmlDocument().data, as: UTF8.self)

        let row2Range = try #require(xml.range(of: #"<row r="2""#))
        let row5Range = try #require(xml.range(of: #"<row r="5""#))
        let row10Range = try #require(xml.range(of: #"<row r="10""#))
        let markerRange = try #require(xml.range(of: #"<marker/>"#))

        #expect(row2Range.lowerBound < row5Range.lowerBound)
        #expect(row5Range.lowerBound < row10Range.lowerBound)
        #expect(row10Range.lowerBound < markerRange.lowerBound)
    }

    @Test func writesCellsSortedBeforeOtherRowChildren() throws {
        let worksheet = try worksheetFile(data: Data("""
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

        worksheet.cell(row: 2, column: 3).value = .string("middle")

        let xml = try String(decoding: worksheet.xmlDocument().data, as: UTF8.self)

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
        #expect(worksheet.existingRowsWithNumber.map(\.0) == [2, 10])
        #expect(worksheet.existingRows.map(\.cellByColumn.isEmpty) == [true, true])
    }

    @Test func returnsExistingRowsWithoutCreatingMissingRows() throws {
        let worksheet = XLWorksheetFile(rowByNumber: [
            2: XLRowStorage(cellByColumn: [
                1: XLCellStorage(value: .string("left")),
            ]),
        ])

        let row = try #require(worksheet.existingRow(2))
        #expect(row.existingColumnNumbers == [1])
        #expect(row.existingCell(column: 1)?.value == .string("left"))
        #expect(worksheet.existingRow(3) == nil)
        #expect(worksheet.existingRowNumbers == [2])
    }

    @Test func createsMissingRowsWhenAccessed() {
        let worksheet = XLWorksheetFile()

        #expect(worksheet.maxRowNumber == nil)
        #expect(worksheet.existingRow(3) == nil)

        #expect(worksheet.row(3).cellByColumn.isEmpty)
        #expect(worksheet.existingRow(3)?.cellByColumn.isEmpty == true)
        #expect(worksheet.maxRowNumber == 3)
        #expect(worksheet.existingRowNumbers == [3])
    }

    @Test func editsCellsThroughAccessedRow() {
        let worksheet = XLWorksheetFile()

        worksheet.row(3).cell(column: 2).value = .string("value")

        #expect(worksheet.existingRow(3)?.cellByColumn[2]?.value == .string("value"))
    }

    @Test func editsCellsThroughWorksheetCellAccessors() throws {
        let worksheet = XLWorksheetFile()

        worksheet.cell(row: 3, column: 2).value = .string("left")
        worksheet.cell(address: try #require(XLCellAddress("D4"))).value = .string("right")

        #expect(worksheet.existingRow(3)?.existingCell(column: 2)?.value == .string("left"))
        #expect(worksheet.existingRow(4)?.existingCell(column: 4)?.value == .string("right"))
    }

    @Test func exposesExistingColumnNumbersAndMaxColumnNumber() {
        let row = XLRowStorage(cellByColumn: [
            4: XLCellStorage(value: .string("right")),
            2: XLCellStorage(value: .string("left")),
        ])

        #expect(row.maxColumnNumber == 4)
        #expect(row.existingColumnNumbers == [2, 4])
    }

    @Test func returnsExistingCellsWithoutCreatingMissingCells() {
        let row = XLRowStorage(cellByColumn: [
            2: XLCellStorage(value: .string("left")),
        ])

        #expect(row.existingCell(column: 2)?.value == .string("left"))
        #expect(row.existingCell(column: 2)?.format == nil)
        #expect(row.existingCell(column: 3) == nil)
        #expect(row.existingColumnNumbers == [2])
    }

    @Test func createsMissingCellsWhenAccessed() {
        let row = XLRowStorage(cellByColumn: [:])

        #expect(row.maxColumnNumber == nil)
        #expect(row.existingCell(column: 3) == nil)

        #expect(row.cell(column: 3).value == .string(""))
        #expect(row.cell(column: 3).format == nil)
        #expect(row.existingCell(column: 3)?.value == .string(""))
        #expect(row.existingCell(column: 3)?.format == nil)
        #expect(row.maxColumnNumber == 3)
        #expect(row.existingColumnNumbers == [3])
    }

    @Test func patchesKnownCellsWithoutRemovingUnknownCellAttributes() throws {
        let worksheet = try worksheetFile(data: Data("""
            <worksheet xmlns="\(XMLNamespaceURI.spreadsheet.string)">
              <sheetData>
                <row r="1" custom="keep">
                  <c r="A1"><v>0</v></c>
                </row>
              </sheetData>
            </worksheet>
            """.utf8))
        worksheet.rowByNumber[1]?.cellByColumn[1]?.value = .string("1")

        let xml = try String(decoding: worksheet.xmlDocument().data, as: UTF8.self)

        #expect(xml.contains(#"<row r="1" custom="keep">"#))
        #expect(xml.contains(#"<c r="A1"><v>1</v></c>"#))
    }

    @Test func removesStandaloneWorksheetCellFormatWhenWritingWithoutPlan() throws {
        let worksheet = try worksheetFile(data: Data("""
            <worksheet xmlns="\(XMLNamespaceURI.spreadsheet.string)">
              <sheetData>
                <row r="1">
                  <c r="A1" s="2"><v>42</v></c>
                </row>
              </sheetData>
            </worksheet>
            """.utf8))

        let xml = try String(decoding: worksheet.xmlDocument().data, as: UTF8.self)

        #expect(xml.contains(#"<c r="A1"><v>42</v></c>"#))
    }

    private func worksheetFile(data: Data) throws -> XLWorksheetFile {
        try XLWorksheetFile(
            xmlDocument: XMLDocument(data: data),
            sharedStrings: XLSharedStringsFile(),
            styles: XLStylesFile()
        )
    }
}
