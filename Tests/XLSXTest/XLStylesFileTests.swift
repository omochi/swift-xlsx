import Foundation
import Testing
import XLSX

@Suite
struct XLStylesFileTests {
    @Test func readsCellFormatsFromCellXfs() throws {
        let styles = try XLStylesFile(data: Data("""
            <styleSheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">
              <cellXfs count="2">
                <xf numFmtId="0" fontId="0" fillId="0" borderId="0" xfId="0"/>
                <xf numFmtId="14" fontId="1" fillId="2" borderId="3" xfId="4" applyNumberFormat="1" applyFont="0"/>
              </cellXfs>
            </styleSheet>
            """.utf8))

        #expect(styles.cellFormats.objects.map(\.record) == [
            XLCellFormatRecord(
                numberFormatID: 0,
                fontID: 0,
                fillID: 0,
                borderID: 0,
                formatID: 0
            ),
            XLCellFormatRecord(
                numberFormatID: 14,
                fontID: 1,
                fillID: 2,
                borderID: 3,
                formatID: 4,
                applyNumberFormat: true,
                applyFont: false
            ),
        ])
    }

    @Test func patchesCellFormatsWithoutRemovingOtherStyleChildren() throws {
        let styles = try XLStylesFile(data: Data("""
            <styleSheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">
              <numFmts count="1"><numFmt numFmtId="164" formatCode="yyyy-mm-dd"/></numFmts>
              <cellXfs count="1">
                <xf numFmtId="0" fontId="0" fillId="0" borderId="0" xfId="0"/>
              </cellXfs>
              <opaqueStyle/>
            </styleSheet>
            """.utf8))

        styles.cellFormats = XLCellFormatObjectPool(records: [
            XLCellFormatRecord(
                numberFormatID: 164,
                fontID: 1,
                fillID: 2,
                borderID: 3,
                formatID: 0,
                applyNumberFormat: true,
                applyFont: true
            ),
            XLCellFormatRecord(formatID: 0, applyProtection: false),
        ])

        let xml = try String(decoding: styles.data(), as: UTF8.self)

        #expect(xml.contains(#"<numFmts count="1"><numFmt numFmtId="164" formatCode="yyyy-mm-dd"/></numFmts>"#))
        #expect(xml.contains(#"<opaqueStyle/>"#))
        #expect(xml.contains(#"<cellXfs count="2">"#))
        #expect(xml.contains(#"<xf numFmtId="164" fontId="1" fillId="2" borderId="3" xfId="0" applyNumberFormat="1" applyFont="1"/>"#))
        #expect(xml.contains(#"<xf xfId="0"/>"#))
        #expect(!xml.contains(#"applyProtection="0""#))
    }

    @Test func doesNotCreateCellXfsWhenOriginalHasNoneAndCellFormatsAreEmpty() throws {
        let styles = try XLStylesFile(data: Data("""
            <styleSheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">
              <opaqueStyle/>
            </styleSheet>
            """.utf8))

        let xml = try String(decoding: styles.data(), as: UTF8.self)

        #expect(!xml.contains("<cellXfs"))
        #expect(xml.contains(#"<opaqueStyle/>"#))
    }

    @Test func preservesExistingCellXfsTagWhenCellFormatsBecomeEmpty() throws {
        let styles = try XLStylesFile(data: Data("""
            <styleSheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">
              <cellXfs count="1">
                <xf numFmtId="0"/>
              </cellXfs>
            </styleSheet>
            """.utf8))

        styles.cellFormats = XLCellFormatObjectPool()

        let xml = try String(decoding: styles.data(), as: UTF8.self)

        #expect(xml.contains(#"<cellXfs count="0">"#) || xml.contains(#"<cellXfs count="0"/>"#))
        #expect(!xml.contains(#"<xf "#))
    }
}
