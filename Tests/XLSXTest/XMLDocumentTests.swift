import Foundation
import Testing
@testable import XLSX

@Suite
struct XMLDocumentTests {
    @Test func parsesNamespaceAwareElementTree() throws {
        let xml = """
        <?xml version="1.0" encoding="UTF-8"?>
        <workbook xmlns="\(XMLNamespaceURI.spreadsheet.string)" xmlns:r="\(XMLNamespaceURI.officeRelationships.string)">
          <sheets>
            <sheet name="Sheet1" sheetId="1" r:id="rId1"/>
          </sheets>
        </workbook>
        """

        let document = try XMLDocument(data: Data(xml.utf8))
        let workbook = try #require(document.element(name: "workbook"))
        let sheets = try #require(firstChildElement(name: "sheets", of: workbook))
        let sheet = try #require(firstChildElement(name: "sheet", of: sheets))

        #expect(workbook.namespaces.uri() == .spreadsheet)
        #expect(workbook.namespaces.uri(for: "r") == .officeRelationships)
        #expect(workbook.namespaceURI(for: workbook.name.prefix) == .spreadsheet)
        #expect(sheet.namespaceURI(for: sheet.name.prefix) == .spreadsheet)
        let relationshipID = try #require(sheet.attributes.first { $0.name.prefix == "r" && $0.name.name == "id" })
        #expect(sheet.namespaceURI(for: relationshipID.name.prefix) == .officeRelationships)
        #expect(sheet.attribute(
            name: "id",
            namespaceURI: .officeRelationships
        ) == "rId1")
    }

    @Test func parsesDocumentFromXMLString() throws {
        let document = try XMLDocument(xmlString: #"<root><child id="1"/></root>"#)
        let root = try #require(document.element(name: "root"))
        let child = try #require(firstChildElement(name: "child", of: root))

        #expect(child.attribute(name: "id") == "1")
        #expect(root.parent === document)
    }

    @Test func parsesElementFromXMLString() throws {
        let element = try XLSX.XMLElement(xmlString: #"<root><child id="1"/></root>"#)
        let child = try #require(firstChildElement(name: "child", of: element))

        #expect(element.parent == nil)
        #expect(child.parent === element)
        #expect(child.attribute(name: "id") == "1")
    }

    @Test func parsesElementFromData() throws {
        let element = try XLSX.XMLElement(data: Data(#"<root value="a&amp;b"/>"#.utf8))

        #expect(element.attribute(name: "value") == "a&b")
    }

    @Test func serializesUnknownElementsAndEscapesValues() throws {
        let xml = """
        <root xmlns="urn:test" custom="a&amp;b"><known value="&quot;x&quot;"><child>raw &lt; value</child></known></root>
        """

        let document = try XMLDocument(data: Data(xml.utf8))
        let output = document.xmlString

        #expect(output.contains(#"<root xmlns="urn:test" custom="a&amp;b">"#))
        #expect(output.contains(#"<known value="&quot;x&quot;">"#))
        #expect(output.contains("<child>raw &lt; value</child>"))
    }

    @Test func serializesElementAsXMLString() throws {
        let element = XMLElement(
            name: XMLName(name: "root"),
            attributes: [
                XMLAttribute(name: XMLName(name: "custom"), value: "a&b"),
            ],
            children: [
                XMLElement(
                    name: XMLName(name: "child"),
                    children: [XMLText("raw < value")]
                ),
            ]
        )

        let output = element.xmlString

        #expect(output == #"<root custom="a&amp;b"><child>raw &lt; value</child></root>"#)
    }

    @Test func parsesNamespaceDeclarationOnNestedElement() throws {
        let xml = """
        <root>
          <child xmlns:a="urn:nested">
            <a:item a:id="1"/>
          </child>
        </root>
        """

        let document = try XMLDocument(data: Data(xml.utf8))
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

        let document = try XMLDocument(data: Data(xml.utf8))
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

    @Test func internsNamespaceURIInstancesGlobally() {
        let first = XMLNamespaceURI("urn:test")
        let second = XMLNamespaceURI("urn:test")
        let other = XMLNamespaceURI("urn:other")

        #expect(first == second)
        #expect(first != other)
    }

    @Test func clonesDocumentTreeWithoutSharingNodes() throws {
        let xml = """
        <root xmlns="urn:root">
          <child id="1">value</child>
        </root>
        """
        let document = try XMLDocument(data: Data(xml.utf8))
        let clone = document.clone()
        let originalRoot = try #require(document.element(name: "root"))
        let clonedRoot = try #require(clone.element(name: "root"))
        let originalChild = try #require(firstChildElement(name: "child", of: originalRoot))
        let clonedChild = try #require(firstChildElement(name: "child", of: clonedRoot))
        let originalText = try #require(originalChild.children.first as? XMLText)
        let clonedText = try #require(clonedChild.children.first as? XMLText)

        clonedChild.attributes[0].value = "2"
        clonedText.value = "changed"

        #expect(clonedRoot !== originalRoot)
        #expect(clonedChild !== originalChild)
        #expect(clonedText !== originalText)
        #expect(clonedRoot.parent === clone)
        #expect(clonedChild.parent === clonedRoot)
        #expect(clonedChild.attribute(name: "id") == "2")
        #expect(originalChild.attribute(name: "id") == "1")
        #expect(clonedText.value == "changed")
        #expect(originalText.value == "value")
    }

    @Test func cloneKeepsInternedNamespaceURIInstances() throws {
        let document = try XMLDocument(data: Data(#"<root xmlns="urn:root"/>"#.utf8))
        let clone = document.clone()
        let root = try #require(clone.element(name: "root"))
        let declaredURI = try #require(root.namespaces.uri())

        #expect(XMLNamespaceURI("urn:root") == declaredURI)
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

    @Test func insertsChildNode() {
        let parent = XMLElement(name: XMLName(name: "parent"))
        let first = XMLElement(name: XMLName(name: "first"))
        let second = XMLElement(name: XMLName(name: "second"))
        let inserted = XMLElement(name: XMLName(name: "inserted"))
        parent.appendChild(first)
        parent.appendChild(second)

        parent.insertChild(inserted, at: 1)

        #expect(parent.children.count == 3)
        #expect(parent.children[0] === first)
        #expect(parent.children[1] === inserted)
        #expect(parent.children[2] === second)
        #expect(inserted.parent === parent)
    }

    @Test func replacingChildrenUpdatesParentLinks() {
        let oldParent = XMLElement(name: XMLName(name: "oldParent"))
        let newParent = XMLElement(name: XMLName(name: "newParent"))
        let removed = XMLElement(name: XMLName(name: "removed"))
        let moved = XMLElement(name: XMLName(name: "moved"))
        let added = XMLElement(name: XMLName(name: "added"))
        oldParent.appendChild(removed)
        oldParent.appendChild(moved)

        newParent.children = [moved, added]

        #expect(oldParent.children.count == 1)
        #expect(oldParent.children.first === removed)
        #expect(removed.parent === oldParent)
        #expect(moved.parent === newParent)
        #expect(added.parent === newParent)
        #expect(newParent.children.count == 2)
        #expect(newParent.children[0] === moved)
        #expect(newParent.children[1] === added)
    }

    @Test func replacingChildrenDetachesRemovedChildren() {
        let parent = XMLElement(name: XMLName(name: "parent"))
        let kept = XMLElement(name: XMLName(name: "kept"))
        let removed = XMLElement(name: XMLName(name: "removed"))
        parent.appendChild(kept)
        parent.appendChild(removed)

        parent.children = [kept]

        #expect(kept.parent === parent)
        #expect(removed.parent == nil)
        #expect(parent.children.count == 1)
        #expect(parent.children.first === kept)
    }

    @Test func setAttributeUsesDeclaredNamespacePrefix() throws {
        let parent = XMLElement(name: XMLName(name: "parent"))
        parent.ensureNamespace(prefix: "rel", uri: .officeRelationships)
        let child = XMLElement(name: XMLName(name: "child"))
        parent.appendChild(child)

        try child.setAttribute(
            name: "id",
            namespaceURI: .officeRelationships,
            value: "rId1"
        )

        #expect(child.attributes.count == 1)
        #expect(child.attributes.first?.name == XMLName(prefix: "rel", name: "id"))
        #expect(child.attributes.first?.value == "rId1")
    }

    @Test func xmlUtilsSetAttributeWritesBoolValuesAndRemovesNilValues() {
        let element = XMLElement(name: XMLName(name: "element"))

        XMLUtils.setBoolAttribute(name: "enabled", value: true, in: element)
        #expect(element.attribute(name: "enabled") == XMLUtils.boolString(value: true))
        #expect(XLCellValue.boolean(true).description == XMLUtils.boolString(value: true))

        XMLUtils.setBoolAttribute(name: "enabled", value: false, in: element)
        #expect(element.attribute(name: "enabled") == XMLUtils.boolString(value: false))
        #expect(XLCellValue.boolean(false).description == XMLUtils.boolString(value: false))

        XMLUtils.setBoolAttribute(name: "enabled", value: Optional<Bool>.none, in: element)
        #expect(element.attribute(name: "enabled") == nil)

        XMLUtils.setIntAttribute(name: "count", value: 1, in: element)
        #expect(element.attribute(name: "count") == "1")

        XMLUtils.setIntAttribute(name: "count", value: Optional<Int>.none, in: element)
        #expect(element.attribute(name: "count") == nil)
    }

    @Test func ensureNamespaceURIReusesExistingPrefixForURI() {
        let element = XMLElement(name: XMLName(name: "element"))
        element.ensureNamespace(prefix: "rel", uri: .officeRelationships)

        let prefix = element.ensureNamespaceURI(prefix: "r", uri: .officeRelationships)

        #expect(prefix == "rel")
        #expect(element.namespaces.declarations.count == 1)
        #expect(element.namespaces.uri(for: "rel") == .officeRelationships)
    }

    @Test func ensureNamespaceURIChoosesAvailablePrefixedName() {
        let element = XMLElement(name: XMLName(name: "element"))
        element.ensureNamespace(prefix: "r", uri: XMLNamespaceURI("urn:other"))
        element.ensureNamespace(prefix: "r2", uri: XMLNamespaceURI("urn:other-2"))

        let prefix = element.ensureNamespaceURI(prefix: "r", uri: .officeRelationships)

        #expect(prefix == "r3")
        #expect(element.namespaces.uri(for: "r")?.string == "urn:other")
        #expect(element.namespaces.uri(for: "r2")?.string == "urn:other-2")
        #expect(element.namespaces.uri(for: "r3") == .officeRelationships)
    }
}

private func firstChildElement(name: String, of element: XLSX.XMLElement) -> XLSX.XMLElement? {
    element.elements(name: name).first
}
