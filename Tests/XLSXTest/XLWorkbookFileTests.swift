import Foundation
import Testing
import XLSX

@Suite
struct XLWorkbookFileTests {
    @Test func readsSheetsFromWorkbookXML() throws {
        let workbook = try XLWorkbookFile(data: Data("""
            <workbook xmlns="\(XMLNamespaceURI.spreadsheet.string)" xmlns:rel="\(XMLNamespaceURI.officeRelationships.string)">
              <sheets>
                <sheet name="First" sheetId="1" rel:id="rId1"/>
                <sheet name="Second" sheetId="4" rel:id="rId7"/>
              </sheets>
            </workbook>
            """.utf8))

        #expect(workbook.sheets == [
            XLWorkbookFileSheet(name: "First", sheetID: 1, relationshipID: "rId1"),
            XLWorkbookFileSheet(name: "Second", sheetID: 4, relationshipID: "rId7"),
        ])
    }

    @Test func writesSheetsFromWorkbookModel() throws {
        let workbook = XLWorkbookFile(sheets: [
            XLWorkbookFileSheet(name: "First", sheetID: 1, relationshipID: "rId1"),
            XLWorkbookFileSheet(name: "Second", sheetID: 4, relationshipID: "rId7"),
        ])

        let xml = try String(decoding: workbook.data(), as: UTF8.self)

        #expect(xml.contains(#"<sheet name="First" sheetId="1" r:id="rId1"/>"#))
        #expect(xml.contains(#"<sheet name="Second" sheetId="4" r:id="rId7"/>"#))
    }

    @Test func patchesKnownSheetElementsWithoutRemovingUnknownContent() throws {
        let workbook = try XLWorkbookFile(data: Data("""
            <workbook xmlns="\(XMLNamespaceURI.spreadsheet.string)" xmlns:rel="\(XMLNamespaceURI.officeRelationships.string)">
              <sheets>
                <sheet name="Old" sheetId="1" rel:id="rId1" state="hidden"/>
                <sheet name="External" sheetId="9" rel:id="rId9" custom="keep"/>
              </sheets>
            </workbook>
            """.utf8))
        workbook.sheets = [
            XLWorkbookFileSheet(name: "New", sheetID: 1, relationshipID: "rId1"),
            XLWorkbookFileSheet(name: "Added", sheetID: 2, relationshipID: "rId2"),
        ]

        let xml = try String(decoding: workbook.data(), as: UTF8.self)

        #expect(xml.contains(#"<sheet name="New" sheetId="1" rel:id="rId1" state="hidden"/>"#))
        #expect(xml.contains(#"<sheet name="External" sheetId="9" rel:id="rId9" custom="keep"/>"#))
        #expect(xml.contains(#"<sheet name="Added" sheetId="2" rel:id="rId2"/>"#))
        #expect(!xml.contains("xmlns:r="))
    }

    @Test func patchesSheetElementsBySheetID() throws {
        let workbook = try XLWorkbookFile(data: Data("""
            <workbook xmlns="\(XMLNamespaceURI.spreadsheet.string)" xmlns:rel="\(XMLNamespaceURI.officeRelationships.string)">
              <sheets>
                <sheet name="Original" sheetId="1" rel:id="rId1"/>
                <sheet name="Other" sheetId="2" rel:id="rId2"/>
              </sheets>
            </workbook>
            """.utf8))
        workbook.sheets = [
            XLWorkbookFileSheet(name: "Moved", sheetID: 1, relationshipID: "rId3"),
        ]

        let xml = try String(decoding: workbook.data(), as: UTF8.self)

        #expect(xml.contains(#"<sheet name="Moved" sheetId="1" rel:id="rId3"/>"#))
        #expect(xml.contains(#"<sheet name="Other" sheetId="2" rel:id="rId2"/>"#))
    }

    @Test func addsRelationshipNamespaceWithoutOverwritingExistingPrefix() throws {
        let workbook = try XLWorkbookFile(xmlDocument: XMLDocumentReader.parse(Data("""
            <workbook xmlns="\(XMLNamespaceURI.spreadsheet.string)" xmlns:r="urn:other">
              <sheets/>
            </workbook>
            """.utf8)))
        workbook.sheets = [
            XLWorkbookFileSheet(name: "Sheet1", sheetID: 1, relationshipID: "rId1"),
        ]

        let xml = try String(decoding: workbook.data(), as: UTF8.self)

        #expect(xml.contains(#"xmlns:r="urn:other""#))
        #expect(xml.contains(#"xmlns:r2="http://schemas.openxmlformats.org/officeDocument/2006/relationships""#))
        #expect(xml.contains(#"<sheet name="Sheet1" sheetId="1" r2:id="rId1"/>"#))
    }
}
