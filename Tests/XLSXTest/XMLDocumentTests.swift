import Foundation
import Testing
@testable import XLSX

@Suite
struct XMLDocumentTests {
    @Test func parsesNamespaceAwareElementTree() throws {
        let xml = """
        <?xml version="1.0" encoding="UTF-8"?>
        <workbook xmlns="\(XLXMLNamespaces.spreadsheet)" xmlns:r="\(XLXMLNamespaces.officeRelationships)">
          <sheets>
            <sheet name="Sheet1" sheetId="1" r:id="rId1"/>
          </sheets>
        </workbook>
        """

        let document = try XMLDocumentReader.parse(Data(xml.utf8))
        let spreadsheet = try #require(document.namespaces.uriToID[XLXMLNamespaces.spreadsheet])
        let relationships = try #require(document.namespaces.uriToID[XLXMLNamespaces.officeRelationships])
        let workbook = try #require(XMLDocument.firstElement(named: "workbook", in: document))
        let sheet = try #require(XMLDocument.firstElement(named: "sheet", in: document))

        #expect(workbook.name.namespaceID == spreadsheet)
        #expect(sheet.name.namespaceID == spreadsheet)
        #expect(sheet.attributes.first { $0.name.rawName == "r:id" }?.name.namespaceID == relationships)
        #expect(XMLDocument.attribute("r:id", of: sheet, in: document) == "rId1")
    }

    @Test func serializesUnknownElementsAndEscapesValues() throws {
        let xml = """
        <root xmlns="urn:test" custom="a&amp;b"><known value="&quot;x&quot;"><child>raw &lt; value</child></known></root>
        """

        let document = try XMLDocumentReader.parse(Data(xml.utf8))
        let output = String(decoding: document.data(), as: UTF8.self)

        #expect(output.contains(#"<root xmlns="urn:test" custom="a&amp;b">"#))
        #expect(output.contains(#"<known value="&quot;x&quot;">"#))
        #expect(output.contains("<child>raw &lt; value</child>"))
    }

    @Test func removesChildNode() {
        let parent = XMLElement(name: XMLName(rawName: "parent", namespaceID: nil))
        let child = XMLElement(name: XMLName(rawName: "child", namespaceID: nil))
        parent.appendChild(child)

        let removed = parent.removeChild(child)

        #expect(removed === child)
        #expect(parent.children.isEmpty)
        #expect(child.parent == nil)
    }
}
