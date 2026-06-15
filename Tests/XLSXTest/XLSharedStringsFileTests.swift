import Foundation
import Testing
import XLSX

@Suite
struct XLSharedStringsFileTests {
    @Test func readsPlainSharedStrings() throws {
        let sharedStrings = try XLSharedStringsFile(data: Data("""
            <sst xmlns="\(XMLNamespaceURI.spreadsheet.string)" count="3" uniqueCount="2">
              <si><t>hello</t></si>
              <si><t>world</t></si>
            </sst>
            """.utf8))

        #expect(sharedStrings.records.count == 2)
        #expect(sharedStrings.records.compactMap(\.item) == [
            XLSharedStringItem(text: "hello"),
            XLSharedStringItem(text: "world"),
        ])
    }

    @Test func doesNotDecodeRichTextRecordAsItem() throws {
        let sharedStrings = try XLSharedStringsFile(data: Data("""
            <sst xmlns="\(XMLNamespaceURI.spreadsheet.string)">
              <si>
                <r><rPr><b/></rPr><t>Hello</t></r>
                <r><t> world</t></r>
              </si>
            </sst>
            """.utf8))

        #expect(sharedStrings.records.count == 1)
        #expect(sharedStrings.records.first?.item == nil)
    }

    @Test func preservesUnchangedRichTextItemsWhenWriting() throws {
        let sharedStrings = try XLSharedStringsFile(data: Data("""
            <sst xmlns="\(XMLNamespaceURI.spreadsheet.string)" count="1" uniqueCount="1">
              <si><r><rPr><b/></rPr><t>Hello</t></r><r><t> world</t></r></si>
              <extLst><ext uri="keep"/></extLst>
            </sst>
            """.utf8))

        let xml = try String(decoding: sharedStrings.data(), as: UTF8.self)

        #expect(xml.contains(#"<rPr><b/></rPr>"#))
        #expect(xml.contains(#"<extLst><ext uri="keep"/></extLst>"#))
    }

    @Test func appendsChangedItemsAsPlainText() throws {
        let sharedStrings = try XLSharedStringsFile(data: Data("""
            <sst xmlns="\(XMLNamespaceURI.spreadsheet.string)" count="1" uniqueCount="1">
              <si><r><rPr><b/></rPr><t>Hello</t></r></si>
            </sst>
            """.utf8))
        sharedStrings.records.append(sharedStringRecord(index: 1, text: "Changed"))

        let xml = try String(decoding: sharedStrings.data(), as: UTF8.self)

        #expect(xml.contains(#"<si><t>Changed</t></si>"#))
        #expect(xml.contains(#"<rPr><b/></rPr>"#))
    }

    @Test func appendsAddedItemsAfterOriginalChildren() throws {
        let sharedStrings = try XLSharedStringsFile(data: Data("""
            <sst xmlns="\(XMLNamespaceURI.spreadsheet.string)" count="1" uniqueCount="1">
              <si><t>A</t></si>
              <extLst><ext uri="keep"/></extLst>
            </sst>
            """.utf8))
        sharedStrings.records.append(sharedStringRecord(index: 1, text: "B"))

        let xml = try String(decoding: sharedStrings.data(), as: UTF8.self)
            .replacingOccurrences(of: "\n", with: "")
            .replacingOccurrences(of: "  ", with: "")

        #expect(xml.contains(#"<si><t>A</t></si><extLst><ext uri="keep"/></extLst><si><t>B</t></si>"#))
    }

    @Test func keepsExistingRecordOrderWhenNewRecordIsAppended() throws {
        let sharedStrings = try XLSharedStringsFile(data: Data("""
            <sst xmlns="\(XMLNamespaceURI.spreadsheet.string)" count="3" uniqueCount="3">
              <si><t>A</t></si>
              <si><t>B</t></si>
              <si><t>C</t></si>
            </sst>
            """.utf8))
        sharedStrings.records.append(sharedStringRecord(index: 3, text: "X"))

        let xml = try String(decoding: sharedStrings.data(), as: UTF8.self)
            .replacingOccurrences(of: "\n", with: "")
            .replacingOccurrences(of: "  ", with: "")

        #expect(xml.contains(#"<si><t>A</t></si><si><t>B</t></si><si><t>C</t></si><si><t>X</t></si>"#))
    }

    @Test func rejectsSharedStringsFileWithoutSharedStringsRoot() throws {
        do {
            _ = try XLSharedStringsFile(data: Data("<Root/>".utf8))
            Issue.record("Expected invalid shared strings file error.")
        } catch let error as OPCError {
            #expect(error == .invalidSharedStringsFile)
        }
    }

    private func sharedStringRecord(index: Int, text: String) -> XLSharedStringRecord {
        let item = XLSharedStringItem(text: text)
        let itemElement = XMLElement(name: XMLName(name: "si"))
        let textElement = XMLElement(name: XMLName(name: "t"))
        textElement.appendChild(XMLText(text))
        itemElement.appendChild(textElement)
        return XLSharedStringRecord(
            index: index,
            childIndex: nil,
            item: item,
            element: itemElement
        )
    }
}
