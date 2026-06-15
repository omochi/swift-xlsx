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

        #expect(sharedStrings.count == 3)
        #expect(sharedStrings.uniqueCount == 2)
        #expect(sharedStrings.items == [
            XLSharedStringItem(text: "hello"),
            XLSharedStringItem(text: "world"),
        ])
    }

    @Test func readsRichTextAsPlainText() throws {
        let sharedStrings = try XLSharedStringsFile(data: Data("""
            <sst xmlns="\(XMLNamespaceURI.spreadsheet.string)">
              <si>
                <r><rPr><b/></rPr><t>Hello</t></r>
                <r><t> world</t></r>
              </si>
            </sst>
            """.utf8))

        #expect(sharedStrings.items == [
            XLSharedStringItem(text: "Hello world"),
        ])
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

    @Test func patchesChangedItemsAsPlainText() throws {
        let sharedStrings = try XLSharedStringsFile(data: Data("""
            <sst xmlns="\(XMLNamespaceURI.spreadsheet.string)" count="1" uniqueCount="1">
              <si><r><rPr><b/></rPr><t>Hello</t></r></si>
            </sst>
            """.utf8))
        sharedStrings.items = [
            XLSharedStringItem(text: "Changed"),
        ]

        let xml = try String(decoding: sharedStrings.data(), as: UTF8.self)

        #expect(xml.contains(#"<si><t>Changed</t></si>"#))
        #expect(!xml.contains("<rPr>"))
    }

    @Test func rejectsSharedStringsFileWithoutSharedStringsRoot() throws {
        do {
            _ = try XLSharedStringsFile(data: Data("<Root/>".utf8))
            Issue.record("Expected invalid shared strings file error.")
        } catch let error as OPCError {
            #expect(error == .invalidSharedStringsFile)
        }
    }
}
