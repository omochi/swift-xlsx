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
        copy.color = .rgb("FFFF0000")

        #expect(original == XLFontRecord(bold: true, size: 11, name: "Calibri"))
        #expect(copy == XLFontRecord(
            bold: true,
            italic: true,
            size: 12,
            color: .rgb("FFFF0000"),
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
            color: .rgb("FFFF0000"),
            name: "Arial",
            familyXMLString: #"<family val="2"/>"#
        )

        #expect(XLFont(record: record) == XLFont(
            bold: true,
            italic: true,
            condense: true,
            underlineXMLString: #"<u val="single"/>"#,
            size: 12,
            color: .rgb("FFFF0000"),
            name: "Arial",
            familyXMLString: #"<family val="2"/>"#
        ))
    }

    @Test func cellFormatUpdatesApplyFontWhenFontChanges() {
        var format = XLCellFormat()

        format.font = XLFont(bold: true)
        #expect(format.applyFont)

        format.applyFont = false
        #expect(!format.applyFont)

        format.font = nil
        #expect(!format.applyFont)

        format.font = XLFont(italic: true)
        #expect(format.applyFont)
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
              <fonts count="3">
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
                  <color theme="4" tint="0.4"/>
                  <name val="Arial"/>
                </font>
                <font>
                  <color foo="bar"/>
                  <name val="Unknown"/>
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
                color: .theme(1),
                name: "Calibri",
                familyXMLString: #"<family val="2"/>"#,
                schemeXMLString: #"<scheme val="minor"/>"#
            ),
            XLFontRecord(
                underlineXMLString: #"<u val="none"/>"#,
                size: 12.5,
                color: .theme(4, tint: 0.4),
                name: "Arial"
            ),
            XLFontRecord(name: "Unknown"),
        ])
    }

    @Test func writesFontColorVariants() throws {
        let styles = XLStylesFile(fonts: [
            XLFontRecord(color: .rgb("FFFF0000")),
            XLFontRecord(color: .indexed(64)),
            XLFontRecord(color: .theme(4, tint: -0.25)),
            XLFontRecord(color: .auto),
        ])

        let xml = try String(decoding: styles.xmlDocument().data, as: UTF8.self)

        #expect(xml.contains(#"<font><color rgb="FFFF0000"/></font>"#))
        #expect(xml.contains(#"<font><color indexed="64"/></font>"#))
        #expect(xml.contains(#"<font><color theme="4" tint="-0.25"/></font>"#))
        #expect(xml.contains(#"<font><color auto="1"/></font>"#))
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
                color: .rgb("FFFF0000"),
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

    @Test func readsFillsFromFillsElement() throws {
        let styles = try stylesFile(data: Data("""
            <styleSheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">
              <fills count="3">
                <fill><patternFill patternType="none"/></fill>
                <fill>
                  <patternFill patternType="solid">
                    <fgColor rgb="FFFFFF00"/>
                    <bgColor indexed="64"/>
                  </patternFill>
                </fill>
                <fill>
                  <gradientFill degree="45">
                    <stop position="0"><color rgb="FFFFFFFF"/></stop>
                    <stop position="1"><color rgb="FF000000"/></stop>
                  </gradientFill>
                </fill>
              </fills>
            </styleSheet>
            """.utf8))

        #expect(styles.fills.records.count == 3)
        #expect(styles.fills.records.prefix(2) == [
            XLFill.pattern(XLFill.Pattern(patternType: "none")),
            XLFill.pattern(XLFill.Pattern(
                patternType: "solid",
                foregroundColor: .rgb("FFFFFF00"),
                backgroundColor: .indexed(64)
            )),
        ])
        if case let .gradient(xmlString) = styles.fills.records[2] {
            #expect(xmlString.contains(#"<gradientFill degree="45">"#))
            #expect(xmlString.contains(#"<stop position="0"><color rgb="FFFFFFFF"/></stop>"#))
            #expect(xmlString.contains(#"<stop position="1"><color rgb="FF000000"/></stop>"#))
        } else {
            Issue.record("Expected gradient fill")
        }
    }

    @Test func fillPatternStoresTypedColors() {
        let fill = XLFill.pattern(XLFill.Pattern(
            patternType: "solid",
            foregroundColor: .rgb("FFFF0000"),
            backgroundColor: .indexed(64)
        ))

        #expect(fill == .pattern(XLFill.Pattern(
            patternType: "solid",
            foregroundColor: .rgb("FFFF0000"),
            backgroundColor: .indexed(64)
        )))
    }

    @Test func patchesFillsWithoutRemovingOtherStyleChildren() throws {
        let styles = try stylesFile(data: Data("""
            <styleSheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">
              <fonts count="1"><font><name val="Calibri"/></font></fonts>
              <fills count="1">
                <fill><patternFill patternType="none"/></fill>
              </fills>
              <cellXfs count="1"><xf numFmtId="0"/></cellXfs>
            </styleSheet>
            """.utf8))

        styles.fills = XLFillsStorage(records: [
            .pattern(XLFill.Pattern(
                patternType: "solid",
                foregroundColor: .rgb("FFFFFF00"),
                backgroundColor: .indexed(64)
            )),
            .gradient(xmlString: #"<gradientFill degree="45"><stop position="0"><color rgb="FFFFFFFF"/></stop></gradientFill>"#),
        ])

        let xml = try String(decoding: styles.xmlDocument().data, as: UTF8.self)

        #expect(xml.contains(#"<fonts count="1"><font><name val="Calibri"/></font></fonts>"#))
        #expect(xml.contains(#"<fills count="2">"#))
        #expect(xml.contains(#"<fill><patternFill patternType="solid"><fgColor rgb="FFFFFF00"/><bgColor indexed="64"/></patternFill></fill>"#))
        #expect(xml.contains(#"<fill><gradientFill degree="45"><stop position="0"><color rgb="FFFFFFFF"/></stop></gradientFill></fill>"#))
        #expect(xml.contains(#"<cellXfs count="1"><xf numFmtId="0"/></cellXfs>"#))
    }

    @Test func preservesExistingFillsTagWhenFillsBecomeEmpty() throws {
        let styles = try stylesFile(data: Data("""
            <styleSheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">
              <fills count="1">
                <fill><patternFill patternType="none"/></fill>
              </fills>
            </styleSheet>
            """.utf8))

        styles.fills = XLFillsStorage()

        let xml = try String(decoding: styles.xmlDocument().data, as: UTF8.self)

        #expect(xml.contains(#"<fills count="0">"#) || xml.contains(#"<fills count="0"/>"#))
        #expect(!xml.contains("<fill>"))
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
