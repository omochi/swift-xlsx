import Foundation
import Testing
import XLSX

@Suite
struct XLStylesFileTests {
    @Test func fontRecordCopiesOnWrite() {
        let original = XLFontRecord(bold: true, size: 11, name: "Calibri")
        var copy = original

        copy.size = 12
        copy.italic = true
        copy.colorXMLString = #"<color rgb="FFFF0000"/>"#

        #expect(original == XLFontRecord(bold: true, size: 11, name: "Calibri"))
        #expect(copy == XLFontRecord(
            bold: true,
            italic: true,
            size: 12,
            colorXMLString: #"<color rgb="FFFF0000"/>"#,
            name: "Calibri"
        ))
    }

    @Test func fontConvertsFromRecord() {
        let record = XLFontRecord(
            bold: true,
            italic: true,
            condense: true,
            underlineXMLString: #"<u val="single"/>"#,
            size: 12,
            colorXMLString: #"<color rgb="FFFF0000"/>"#,
            name: "Arial",
            familyXMLString: #"<family val="2"/>"#
        )

        #expect(XLFont(record: record) == XLFont(
            bold: true,
            italic: true,
            condense: true,
            underlineXMLString: #"<u val="single"/>"#,
            size: 12,
            colorXMLString: #"<color rgb="FFFF0000"/>"#,
            name: "Arial",
            familyXMLString: #"<family val="2"/>"#
        ))
    }

    @Test func cellFormatRecordCopiesOnWrite() {
        let original = XLCellFormatRecord(numberFormatID: 14, applyNumberFormat: true)
        var copy = original

        copy.numberFormatID = 99
        copy.applyFont = true

        #expect(original == XLCellFormatRecord(numberFormatID: 14, applyNumberFormat: true))
        #expect(copy == XLCellFormatRecord(numberFormatID: 99, applyNumberFormat: true, applyFont: true))
    }

    @Test func readsFontsFromFontsElement() throws {
        let styles = try stylesFile(data: Data("""
            <styleSheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">
              <fonts count="2">
                <font>
                  <b/>
                  <i val="1"/>
                  <strike val="0"/>
                  <condense/>
                  <extend val="1"/>
                  <outline val="0"/>
                  <shadow/>
                  <u val="single"/>
                  <sz val="11"/>
                  <color theme="1"/>
                  <name val="Calibri"/>
                  <family val="2"/>
                  <scheme val="minor"/>
                </font>
                <font>
                  <u val="none"/>
                  <sz val="12.5"/>
                  <name val="Arial"/>
                </font>
              </fonts>
            </styleSheet>
            """.utf8))

        #expect(styles.fonts.records == [
            XLFontRecord(
                bold: true,
                italic: true,
                strike: false,
                condense: true,
                extend: true,
                outline: false,
                shadow: true,
                underlineXMLString: #"<u val="single"/>"#,
                size: 11,
                colorXMLString: #"<color theme="1"/>"#,
                name: "Calibri",
                familyXMLString: #"<family val="2"/>"#,
                schemeXMLString: #"<scheme val="minor"/>"#
            ),
            XLFontRecord(
                underlineXMLString: #"<u val="none"/>"#,
                size: 12.5,
                name: "Arial"
            ),
        ])
    }

    @Test func patchesFontsWithoutRemovingOtherStyleChildren() throws {
        let styles = try stylesFile(data: Data("""
            <styleSheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">
              <numFmts count="1"><numFmt numFmtId="164" formatCode="yyyy-mm-dd"/></numFmts>
              <fonts count="1">
                <font><name val="Calibri"/></font>
              </fonts>
              <cellXfs count="1">
                <xf numFmtId="0" fontId="0" fillId="0" borderId="0" xfId="0"/>
              </cellXfs>
            </styleSheet>
            """.utf8))

        styles.fonts = XLFontRecordsStorage(records: [
            XLFontRecord(
                bold: true,
                condense: true,
                extend: true,
                outline: true,
                shadow: true,
                underlineXMLString: #"<u val="single"/>"#,
                size: 12,
                colorXMLString: #"<color rgb="FFFF0000"/>"#,
                name: "Arial",
                familyXMLString: #"<family val="2"/>"#
            ),
            XLFontRecord(italic: true, name: "Helvetica Neue"),
        ])

        let xml = try String(decoding: styles.xmlDocument().data, as: UTF8.self)

        #expect(xml.contains(#"<numFmts count="1"><numFmt numFmtId="164" formatCode="yyyy-mm-dd"/></numFmts>"#))
        #expect(xml.contains(#"<fonts count="2">"#))
        #expect(xml.contains(#"<font><b/><condense/><extend/><outline/><shadow/><u val="single"/><sz val="12.0"/><color rgb="FFFF0000"/><name val="Arial"/><family val="2"/></font>"#))
        #expect(xml.contains(#"<font><i/><name val="Helvetica Neue"/></font>"#))
        #expect(xml.contains(#"<cellXfs count="1">"#))
    }

    @Test func preservesExistingFontsTagWhenFontsBecomeEmpty() throws {
        let styles = try stylesFile(data: Data("""
            <styleSheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">
              <fonts count="1">
                <font><name val="Calibri"/></font>
              </fonts>
            </styleSheet>
            """.utf8))

        styles.fonts = XLFontRecordsStorage()

        let xml = try String(decoding: styles.xmlDocument().data, as: UTF8.self)

        #expect(xml.contains(#"<fonts count="0">"#) || xml.contains(#"<fonts count="0"/>"#))
        #expect(!xml.contains("<font>"))
    }

    @Test func readsCellFormatsFromCellXfs() throws {
        let styles = try stylesFile(data: Data("""
            <styleSheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">
              <cellXfs count="2">
                <xf numFmtId="0" fontId="0" fillId="0" borderId="0" xfId="0"/>
                <xf numFmtId="14" fontId="1" fillId="2" borderId="3" xfId="4" applyNumberFormat="1" applyFont="0"/>
              </cellXfs>
            </styleSheet>
            """.utf8))

        #expect(styles.cellFormats.records == [
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
        let styles = try stylesFile(data: Data("""
            <styleSheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">
              <numFmts count="1"><numFmt numFmtId="164" formatCode="yyyy-mm-dd"/></numFmts>
              <cellXfs count="1">
                <xf numFmtId="0" fontId="0" fillId="0" borderId="0" xfId="0"/>
              </cellXfs>
              <opaqueStyle/>
            </styleSheet>
            """.utf8))

        styles.cellFormats = XLCellFormatRecordsStorage(records: [
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

        let xml = try String(decoding: styles.xmlDocument().data, as: UTF8.self)

        #expect(xml.contains(#"<numFmts count="1"><numFmt numFmtId="164" formatCode="yyyy-mm-dd"/></numFmts>"#))
        #expect(xml.contains(#"<opaqueStyle/>"#))
        #expect(xml.contains(#"<cellXfs count="2">"#))
        #expect(xml.contains(#"<xf numFmtId="164" fontId="1" fillId="2" borderId="3" xfId="0" applyNumberFormat="1" applyFont="1"/>"#))
        #expect(xml.contains(#"<xf xfId="0"/>"#))
        #expect(!xml.contains(#"applyProtection="0""#))
    }

    @Test func doesNotCreateCellXfsWhenOriginalHasNoneAndCellFormatsAreEmpty() throws {
        let styles = try stylesFile(data: Data("""
            <styleSheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">
              <opaqueStyle/>
            </styleSheet>
            """.utf8))

        let xml = try String(decoding: styles.xmlDocument().data, as: UTF8.self)

        #expect(!xml.contains("<cellXfs"))
        #expect(xml.contains(#"<opaqueStyle/>"#))
    }

    @Test func preservesExistingCellXfsTagWhenCellFormatsBecomeEmpty() throws {
        let styles = try stylesFile(data: Data("""
            <styleSheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">
              <cellXfs count="1">
                <xf numFmtId="0"/>
              </cellXfs>
            </styleSheet>
            """.utf8))

        styles.cellFormats = XLCellFormatRecordsStorage()

        let xml = try String(decoding: styles.xmlDocument().data, as: UTF8.self)

        #expect(xml.contains(#"<cellXfs count="0">"#) || xml.contains(#"<cellXfs count="0"/>"#))
        #expect(!xml.contains(#"<xf "#))
    }

    private func stylesFile(data: Data) throws -> XLStylesFile {
        try XLStylesFile(xmlDocument: XMLDocument(data: data))
    }
}
