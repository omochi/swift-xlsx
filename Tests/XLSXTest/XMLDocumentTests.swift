import Foundation
import Testing
@testable import XLSX

@Suite
struct XMLDocumentTests {
    @Test func parsesNamespaceAwareElementTree() throws {
        let xml = """
        <?xml version="1.0" encoding="UTF-8"?>
        <workbook xmlns="\(XLXMLURIs.spreadsheet)" xmlns:r="\(XLXMLURIs.officeRelationships)">
          <sheets>
            <sheet name="Sheet1" sheetId="1" r:id="rId1"/>
          </sheets>
        </workbook>
        """

        let document = try XMLDocumentReader.parse(Data(xml.utf8))
        let workbook = try #require(document.element(name: "workbook"))
        let sheets = try #require(firstChildElement(name: "sheets", of: workbook))
        let sheet = try #require(firstChildElement(name: "sheet", of: sheets))

        #expect(workbook.namespaces.uri()?.string == XLXMLURIs.spreadsheet)
        #expect(workbook.namespaces.uri(for: "r")?.string == XLXMLURIs.officeRelationships)
        #expect(workbook.namespaceURI(for: workbook.name.prefix)?.string == XLXMLURIs.spreadsheet)
        #expect(sheet.namespaceURI(for: sheet.name.prefix)?.string == XLXMLURIs.spreadsheet)
        let relationshipID = try #require(sheet.attributes.first { $0.name.prefix == "r" && $0.name.name == "id" })
        #expect(sheet.namespaceURI(for: relationshipID.name.prefix)?.string == XLXMLURIs.officeRelationships)
        #expect(sheet.attribute("r:id") == "rId1")
    }

    @Test func serializesUnknownElementsAndEscapesValues() throws {
        let xml = """
        <root xmlns="urn:test" custom="a&amp;b"><known value="&quot;x&quot;"><child>raw &lt; value</child></known></root>
        """

        let document = try XMLDocumentReader.parse(Data(xml.utf8))
        let output = document.xmlString

        #expect(output.contains(#"<root xmlns="urn:test" custom="a&amp;b">"#))
        #expect(output.contains(#"<known value="&quot;x&quot;">"#))
        #expect(output.contains("<child>raw &lt; value</child>"))
    }

    @Test func parsesNamespaceDeclarationOnNestedElement() throws {
        let xml = """
        <root>
          <child xmlns:a="urn:nested">
            <a:item a:id="1"/>
          </child>
        </root>
        """

        let document = try XMLDocumentReader.parse(Data(xml.utf8))
        let root = try #require(document.element(name: "root"))
        let child = try #require(firstChildElement(name: "child", of: root))
        let item = try #require(firstChildElement(name: "item", of: child))

        #expect(child.namespaces.uri(for: "a")?.string == "urn:nested")
        #expect(item.namespaceURI(for: item.name.prefix)?.string == "urn:nested")
        let itemID = try #require(item.attributes.first { $0.name.prefix == "a" && $0.name.name == "id" })
        #expect(item.namespaceURI(for: itemID.name.prefix)?.string == "urn:nested")

        let output = document.xmlString
        #expect(output.contains(#"<child xmlns:a="urn:nested">"#))
    }

    @Test func resolvesNamespaceURIFromNodeScope() throws {
        let xml = """
        <root xmlns="urn:root" xmlns:a="urn:outer">
          <child xmlns:a="urn:inner">
            <a:item>value</a:item>
          </child>
        </root>
        """

        let document = try XMLDocumentReader.parse(Data(xml.utf8))
        let root = try #require(document.element(name: "root"))
        let child = try #require(firstChildElement(name: "child", of: root))
        let item = try #require(firstChildElement(name: "item", of: child))
        let text = try #require(item.children.first)

        #expect(child.namespaceURI()?.string == "urn:root")
        #expect(child.namespaceURI(for: "a")?.string == "urn:inner")
        #expect(item.namespaceURI(for: "a")?.string == "urn:inner")
        #expect(text.namespaceURI(for: "a")?.string == "urn:inner")
        #expect(document.namespaceURI(for: "a") == nil)
    }

    @Test func internsNamespaceURIInstancesInDocument() {
        let document = XLSX.XMLDocument()

        let first = document.internNamespaceURI("urn:test")
        let second = document.internNamespaceURI("urn:test")
        let other = document.internNamespaceURI("urn:other")

        #expect(first === second)
        #expect(first !== other)
    }

    @Test func removesChildNode() {
        let parent = XMLElement(name: XMLName(name: "parent"))
        let child = XMLElement(name: XMLName(name: "child"))
        parent.appendChild(child)

        let removed = parent.removeChild(child)

        #expect(removed === child)
        #expect(parent.children.isEmpty)
        #expect(child.parent == nil)
    }
}

private func firstChildElement(name: String, of element: XLSX.XMLElement) -> XLSX.XMLElement? {
    element.elements(name: name).first
}
