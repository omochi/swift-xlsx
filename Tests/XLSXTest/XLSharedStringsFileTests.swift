import struct Foundation.Data
import OrderedCollections
import Testing
import XLSX
import XLSXXML

@Suite
struct XLSharedStringsFileTests {
    @Test func readsPlainSharedStrings() throws {
        let sharedStringStorage = try sharedStringStorage(data: Data("""
            <sst xmlns="\(XMLNamespaceURI.spreadsheet.string)" count="3" uniqueCount="2">
              <si><t>hello</t></si>
              <si><t>world</t></si>
            </sst>
            """.utf8))

        #expect(sharedStringStorage.count == 2)
        #expect(Array(sharedStringStorage) == [
            .text("hello"),
            .text("world"),
        ])
    }

    @Test func doesNotDecodeRichTextRecordAsItem() throws {
        let sharedStringStorage = try sharedStringStorage(data: Data("""
            <sst xmlns="\(XMLNamespaceURI.spreadsheet.string)">
              <si>
                <r><rPr><b/></rPr><t>Hello</t></r>
                <r><t> world</t></r>
              </si>
            </sst>
            """.utf8))

        let record = try #require(sharedStringStorage.first)
        guard case let .opaque(xmlString) = record else {
            Issue.record("Expected opaque shared string record.")
            return
        }
        #expect(xmlString.contains(#"<rPr><b/></rPr>"#))
    }

    @Test func preservesUnchangedRichTextItemsWhenWriting() throws {
        let sharedStrings = try sharedStringsAndStorage(data: Data("""
            <sst xmlns="\(XMLNamespaceURI.spreadsheet.string)" count="1" uniqueCount="1">
              <si><r><rPr><b/></rPr><t>Hello</t></r><r><t> world</t></r></si>
              <extLst><ext uri="keep"/></extLst>
            </sst>
            """.utf8))

        let xml = try String(
            decoding: sharedStrings.file.xmlDocument(sharedStringStorage: sharedStrings.storage).data(),
            as: UTF8.self
        )

        #expect(xml.contains(#"<rPr><b/></rPr>"#))
        #expect(xml.contains(#"<extLst><ext uri="keep"/></extLst>"#))
    }

    @Test func appendsChangedItemsAsPlainText() throws {
        var sharedStrings = try sharedStringsAndStorage(data: Data("""
            <sst xmlns="\(XMLNamespaceURI.spreadsheet.string)" count="1" uniqueCount="1">
              <si><r><rPr><b/></rPr><t>Hello</t></r></si>
            </sst>
            """.utf8))
        sharedStrings.storage.append(sharedStringRecord(text: "Changed"))

        let xml = try String(
            decoding: sharedStrings.file.xmlDocument(sharedStringStorage: sharedStrings.storage).data(),
            as: UTF8.self
        )

        #expect(xml.contains(#"<si><t>Changed</t></si>"#))
        #expect(xml.contains(#"<rPr><b/></rPr>"#))
    }

    @Test func appendsAddedItemsAfterOriginalChildren() throws {
        var sharedStrings = try sharedStringsAndStorage(data: Data("""
            <sst xmlns="\(XMLNamespaceURI.spreadsheet.string)" count="1" uniqueCount="1">
              <si><t>A</t></si>
              <extLst><ext uri="keep"/></extLst>
            </sst>
            """.utf8))
        sharedStrings.storage.append(sharedStringRecord(text: "B"))

        let xml = try String(
            decoding: sharedStrings.file.xmlDocument(sharedStringStorage: sharedStrings.storage).data(),
            as: UTF8.self
        )
            .replacingOccurrences(of: "\n", with: "")
            .replacingOccurrences(of: "  ", with: "")

        #expect(xml.contains(#"<si><t>A</t></si><extLst><ext uri="keep"/></extLst><si><t>B</t></si>"#))
    }

    @Test func keepsExistingRecordOrderWhenNewRecordIsAppended() throws {
        var sharedStrings = try sharedStringsAndStorage(data: Data("""
            <sst xmlns="\(XMLNamespaceURI.spreadsheet.string)" count="3" uniqueCount="3">
              <si><t>A</t></si>
              <si><t>B</t></si>
              <si><t>C</t></si>
            </sst>
            """.utf8))
        sharedStrings.storage.append(sharedStringRecord(text: "X"))

        let xml = try String(
            decoding: sharedStrings.file.xmlDocument(sharedStringStorage: sharedStrings.storage).data(),
            as: UTF8.self
        )
            .replacingOccurrences(of: "\n", with: "")
            .replacingOccurrences(of: "  ", with: "")

        #expect(xml.contains(#"<si><t>A</t></si><si><t>B</t></si><si><t>C</t></si><si><t>X</t></si>"#))
    }

    @Test func rejectsSharedStringsFileWithoutSharedStringsRoot() throws {
        do {
            _ = try sharedStringsFile(data: Data("<Root/>".utf8))
            Issue.record("Expected invalid shared strings file error.")
        } catch let error as OPCError {
            #expect(error == .invalidSharedStringsFile)
        }
    }

    @Test func writesDetachedOpaqueRecord() throws {
        let element = XMLElement(name: XMLName(name: "si"))
        let runElement = XMLElement(name: XMLName(name: "r"))
        let textElement = XMLElement(name: XMLName(name: "t"))
        textElement.appendChild(XMLText("Detached"))
        runElement.appendChild(textElement)
        element.appendChild(runElement)

        let sharedStrings = XLSharedStringsFile()
        let sharedStringStorage = OrderedSet<XLSharedStringRecord>([
            .opaque(xmlString: element.xmlString())
        ])

        let xml = try String(
            decoding: sharedStrings.xmlDocument(sharedStringStorage: sharedStringStorage).data(),
            as: UTF8.self
        )

        #expect(xml.contains(#"<si><r><t>Detached</t></r></si>"#))
    }

    private func sharedStringRecord(text: String) -> XLSharedStringRecord {
        .text(text)
    }

    private func sharedStringsFile(data: Data) throws -> XLSharedStringsFile {
        try XLSharedStringsFile(xmlDocument: XMLDocument(data: data))
    }

    private func sharedStringStorage(data: Data) throws -> OrderedSet<XLSharedStringRecord> {
        try XLSharedStringsFile.readStorage(xmlDocument: XMLDocument(data: data))
    }

    private func sharedStringsAndStorage(
        data: Data
    ) throws -> (file: XLSharedStringsFile, storage: OrderedSet<XLSharedStringRecord>) {
        let document = try XMLDocument(data: data)
        return (
            file: try XLSharedStringsFile(xmlDocument: document),
            storage: try XLSharedStringsFile.readStorage(xmlDocument: document)
        )
    }
}
