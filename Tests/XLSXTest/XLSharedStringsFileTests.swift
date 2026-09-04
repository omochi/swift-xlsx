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
            XLText("hello"),
            XLText("world"),
        ])
    }

    @Test func valueEqualityProvidesSharedStringIndices() {
        let withPhonetics = XLText(
            content: .plain("100"),
            phoneticProperties: XLPhoneticProperties(fontID: 2)
        )
        var sharedStringStorage = OrderedSet<XLText>()

        sharedStringStorage.append(withPhonetics)
        sharedStringStorage.append(withPhonetics)
        sharedStringStorage.append(XLText("100"))

        #expect(sharedStringStorage.count == 2)
        #expect(sharedStringStorage.firstIndex(of: withPhonetics) == 0)
        #expect(sharedStringStorage.firstIndex(of: XLText("100")) == 1)
    }

    @Test func readsRichTextRuns() throws {
        let sharedStringStorage = try sharedStringStorage(data: Data("""
            <sst xmlns="\(XMLNamespaceURI.spreadsheet.string)">
              <si>
                <r><rPr><b/></rPr><t>Hello</t></r>
                <r><t> world</t></r>
              </si>
            </sst>
            """.utf8))

        let text = try #require(sharedStringStorage.first)
        guard case .rich(let runs) = text.content else {
            Issue.record("Expected rich text runs.")
            return
        }
        #expect(runs.count == 2)
        #expect(runs[0].text == "Hello")
        #expect(runs[0].font?.bold == true)
        #expect(runs[1] == XLTextRun(text: " world"))
        #expect(text.string == "Hello world")
        #expect(text.description == text.string)
    }

    @Test func exposesPlainTextWithoutDroppingPhoneticProperties() throws {
        let sharedStrings = try sharedStringsAndStorage(data: Data("""
            <sst xmlns="\(XMLNamespaceURI.spreadsheet.string)">
              <si><t>100</t><phoneticPr fontId="2"/></si>
            </sst>
            """.utf8))

        let text = try #require(sharedStrings.storage.first)
        #expect(text.content == .plain("100"))
        #expect(text.phoneticRuns.isEmpty)
        #expect(text.phoneticProperties == XLPhoneticProperties(fontID: 2))
        #expect(text.string == "100")

        let xml = try String(
            decoding: sharedStrings.file.xmlDocument(sharedStringStorage: sharedStrings.storage).data(),
            as: UTF8.self
        )
        #expect(xml.contains(#"<si><t>100</t><phoneticPr fontId="2"/></si>"#))
    }

    @Test func readsAndWritesPhoneticRuns() throws {
        let sharedStrings = try sharedStringsAndStorage(data: Data("""
            <sst xmlns="\(XMLNamespaceURI.spreadsheet.string)">
              <si>
                <t>漢字</t>
                <rPh sb="0" eb="2"><t>かんじ</t></rPh>
                <phoneticPr fontId="3" type="fullwidthKatakana" alignment="center"/>
              </si>
            </sst>
            """.utf8))

        let text = try #require(sharedStrings.storage.first)
        #expect(text.string == "漢字")
        #expect(text.phoneticRuns == [XLPhoneticRun(text: "かんじ", startIndex: 0, endIndex: 2)])
        #expect(
            text.phoneticProperties == XLPhoneticProperties(
                fontID: 3,
                type: "fullwidthKatakana",
                alignment: "center"
            )
        )

        let xml = try String(
            decoding: sharedStrings.file.xmlDocument(sharedStringStorage: sharedStrings.storage).data(),
            as: UTF8.self
        )
        #expect(xml.contains(#"<rPh sb="0" eb="2"><t>かんじ</t></rPh>"#))
        #expect(xml.contains(#"<phoneticPr fontId="3" type="fullwidthKatakana" alignment="center"/>"#))
    }

    @Test func skipsUnknownTextChildren() throws {
        let sharedStrings = try sharedStringsAndStorage(data: Data("""
            <sst xmlns="\(XMLNamespaceURI.spreadsheet.string)">
              <si><unknown value="drop"/><t>A</t><another>drop</another></si>
            </sst>
            """.utf8))

        #expect(sharedStrings.storage.first == XLText("A"))
        let xml = try String(
            decoding: sharedStrings.file.xmlDocument(sharedStringStorage: sharedStrings.storage).data(),
            as: UTF8.self
        )
        #expect(!xml.contains("unknown"))
        #expect(!xml.contains("another"))
        #expect(xml.contains("<si><t>A</t></si>"))
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
        sharedStrings.storage.append(XLText("Changed"))

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
        sharedStrings.storage.append(XLText("B"))

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
        sharedStrings.storage.append(XLText("X"))

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

    private func sharedStringsFile(data: Data) throws -> XLSharedStringsFile {
        try XLSharedStringsFile(xmlDocument: XMLDocument(data: data))
    }

    private func sharedStringStorage(data: Data) throws -> OrderedSet<XLText> {
        try XLSharedStringsFile.readStorage(xmlDocument: XMLDocument(data: data))
    }

    private func sharedStringsAndStorage(
        data: Data
    ) throws -> (file: XLSharedStringsFile, storage: OrderedSet<XLText>) {
        let document = try XMLDocument(data: data)
        return (
            file: try XLSharedStringsFile(xmlDocument: document),
            storage: try XLSharedStringsFile.readStorage(xmlDocument: document)
        )
    }
}
