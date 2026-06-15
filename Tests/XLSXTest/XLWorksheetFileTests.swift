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

        #expect(worksheet.rowFromNumber == [
            2: XLRowStorage(cellFromColumn: [
                2: XLCellStorage(value: XLCellValue(rawValue: "left")),
                4: XLCellStorage(value: XLCellValue(rawValue: "right")),
            ]),
            10: XLRowStorage(cellFromColumn: [
                3: XLCellStorage(value: XLCellValue(rawValue: "bottom")),
            ]),
        ])
    }

    @Test func writesSparseRowsAndCellsToWorksheetXML() throws {
        let worksheet = XLWorksheetFile(rowFromNumber: [
            10: XLRowStorage(cellFromColumn: [
                3: XLCellStorage(value: XLCellValue(rawValue: "bottom")),
            ]),
            2: XLRowStorage(cellFromColumn: [
                4: XLCellStorage(value: XLCellValue(rawValue: "right")),
                2: XLCellStorage(value: XLCellValue(rawValue: "left")),
            ]),
        ])

        let xml = try String(decoding: worksheet.data(), as: UTF8.self)

        #expect(xml.contains(#"<sheetData><row r="2"><c r="B2"><v>left</v></c><c r="D2"><v>right</v></c></row><row r="10"><c r="C10"><v>bottom</v></c></row></sheetData>"#))
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
        worksheet.rowFromNumber[1]?.cellFromColumn[1]?.value = XLCellValue(rawValue: "1")

        let xml = try String(decoding: worksheet.data(), as: UTF8.self)

        #expect(xml.contains(#"<row r="1" custom="keep">"#))
        #expect(xml.contains(#"<c r="A1" t="s"><v>1</v></c>"#))
    }
}
