import Foundation
import Testing
import XLSX

@Suite
struct XLStylesFileTests {
    @Test func fontRecordCopiesValues() {
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

    @Test func cellStyleFormatRefSharesCellFormatStorage() {
        let styleFormat = XLCellStyleFormatRef(numberFormat: .builtin(id: 14))
        var copy = styleFormat

        copy.numberFormat = .builtin(id: 99)
        copy.font = XLFont(bold: true)

        #expect(styleFormat.numberFormat == .builtin(id: 99))
        #expect(styleFormat.font == XLFont(bold: true))
    }

    @Test func cellStyleFormatRefStoresOnlyParentFormatValues() {
        let styleFormat = XLCellStyleFormatRef(
            numberFormat: .builtin(id: 14),
            font: XLFont(bold: true),
            fill: .pattern(XLFill.Pattern(patternType: "solid")),
            border: XLBorder(left: XLBorder.Line(style: .thin))
        )

        #expect(styleFormat.numberFormat == .builtin(id: 14))
        #expect(styleFormat.font == XLFont(bold: true))
        #expect(styleFormat.fill == .pattern(XLFill.Pattern(patternType: "solid")))
        #expect(styleFormat.border == XLBorder(left: XLBorder.Line(style: .thin)))
    }

    @Test func cellStyleFormatRefHashableUsesIdentifier() {
        let styleFormat = XLCellStyleFormatRef(numberFormat: .builtin(id: 14))
        let copy = styleFormat
        let other = XLCellStyleFormatRef(numberFormat: .builtin(id: 14))

        #expect(styleFormat == copy)
        #expect(styleFormat != other)
        #expect(Set([styleFormat, copy, other]).count == 2)
    }

    @Test func cellFormatRecordCopiesValues() {
        let original = XLCellFormatRecord(numberFormatID: 14, applyNumberFormat: true)
        var copy = original

        copy.numberFormatID = 99
        copy.applyFont = true

        #expect(original == XLCellFormatRecord(numberFormatID: 14, applyNumberFormat: true))
        #expect(copy == XLCellFormatRecord(numberFormatID: 99, applyNumberFormat: true, applyFont: true))
    }

    @Test func readsNumberFormatsFromNumFmts() throws {
        let styles = try stylesFile(data: Data("""
            <styleSheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">
              <numFmts count="2">
                <numFmt numFmtId="165" formatCode="#,##0.000"/>
                <numFmt numFmtId="164" formatCode="yyyy-mm-dd"/>
              </numFmts>
            </styleSheet>
            """.utf8))

        #expect(styles.numberFormats.records == [
            "yyyy-mm-dd",
            "#,##0.000",
        ])
    }

    @Test func patchesNumberFormatsBeforeFonts() throws {
        let styles = try stylesFile(data: Data("""
            <styleSheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">
              <fonts count="1"><font/></fonts>
              <opaqueStyle/>
            </styleSheet>
            """.utf8))

        styles.numberFormats = XLNumberFormatsStorage(records: [
            "yyyy-mm-dd",
            "#,##0.000",
        ])

        let xml = try String(decoding: styles.xmlDocument().data, as: UTF8.self)
        let numberFormatsIndex = try #require(xml.range(of: "<numFmts")?.lowerBound)
        let fontsIndex = try #require(xml.range(of: "<fonts")?.lowerBound)

        #expect(numberFormatsIndex < fontsIndex)
        #expect(xml.contains(##"<numFmts count="2"><numFmt numFmtId="164" formatCode="yyyy-mm-dd"/><numFmt numFmtId="165" formatCode="#,##0.000"/></numFmts>"##))
        #expect(xml.contains(#"<opaqueStyle/>"#))
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
        let styles = XLStylesFile(fonts: XLFontRecordsStorage(records: [
            XLFontRecord(color: .rgb("FFFF0000")),
            XLFontRecord(color: .indexed(64)),
            XLFontRecord(color: .theme(4, tint: -0.25)),
            XLFontRecord(color: .auto),
        ]))

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
            XLFill.pattern(.none),
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

    @Test func readsBordersFromBordersElement() throws {
        let styles = try stylesFile(data: Data("""
            <styleSheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">
              <borders count="2">
                <border>
                  <left/>
                  <right/>
                  <top/>
                  <bottom/>
                  <diagonal/>
                </border>
                <border outline="0" diagonalUp="1">
                  <start style="dotted"/>
                  <end style="hair"/>
                  <left style="thin"><color rgb="FFFF0000"/></left>
                  <right style="medium"/>
                  <top style="dashDot"/>
                  <bottom style="mediumDashDot"><color theme="4" tint="0.25"/></bottom>
                  <diagonal style="double"><color indexed="64"/></diagonal>
                  <vertical style="dashed"/>
                  <horizontal style="thick"/>
                </border>
              </borders>
            </styleSheet>
            """.utf8))

        #expect(styles.borders.records == [
            XLBorder(
                left: XLBorder.Line(),
                right: XLBorder.Line(),
                top: XLBorder.Line(),
                bottom: XLBorder.Line(),
                diagonal: XLBorder.Diagonal(directions: [], line: XLBorder.Line())
            ),
            XLBorder(
                outline: false,
                start: XLBorder.Line(style: .dotted),
                end: XLBorder.Line(style: .hair),
                left: XLBorder.Line(style: .thin, color: .rgb("FFFF0000")),
                right: XLBorder.Line(style: .medium),
                top: XLBorder.Line(style: .dashDot),
                bottom: XLBorder.Line(style: .mediumDashDot, color: .theme(4, tint: 0.25)),
                diagonal: XLBorder.Diagonal(
                    directions: .up,
                    line: XLBorder.Line(style: .double, color: .indexed(64))
                ),
                vertical: XLBorder.Line(style: .dashed),
                horizontal: XLBorder.Line(style: .thick)
            ),
        ])
    }

    @Test func patchesBordersWithoutRemovingOtherStyleChildren() throws {
        let styles = try stylesFile(data: Data("""
            <styleSheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">
              <fonts count="1"><font><name val="Calibri"/></font></fonts>
              <borders count="1">
                <border><left/></border>
              </borders>
              <cellXfs count="1"><xf borderId="0"/></cellXfs>
            </styleSheet>
            """.utf8))

        styles.borders = XLBordersStorage(records: [
            XLBorder(
                left: XLBorder.Line(style: .thin, color: .rgb("FFFF0000")),
                right: XLBorder.Line(style: .medium)
            ),
            XLBorder(
                outline: false,
                diagonal: XLBorder.Diagonal(
                    directions: [.up, .down],
                    line: XLBorder.Line(style: .double, color: .indexed(64))
                ),
                vertical: XLBorder.Line(style: .dashed),
                horizontal: XLBorder.Line(style: .thick)
            ),
        ])

        let xml = try String(decoding: styles.xmlDocument().data, as: UTF8.self)

        #expect(xml.contains(#"<fonts count="1"><font><name val="Calibri"/></font></fonts>"#))
        #expect(xml.contains(#"<borders count="2">"#))
        #expect(xml.contains(#"<border><left style="thin"><color rgb="FFFF0000"/></left><right style="medium"/></border>"#))
        #expect(xml.contains(#"<border outline="0" diagonalUp="1" diagonalDown="1"><diagonal style="double"><color indexed="64"/></diagonal><vertical style="dashed"/><horizontal style="thick"/></border>"#))
        #expect(xml.contains(#"<cellXfs count="1"><xf borderId="0"/></cellXfs>"#))
    }

    @Test func preservesExistingBordersTagWhenBordersBecomeEmpty() throws {
        let styles = try stylesFile(data: Data("""
            <styleSheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">
              <borders count="1">
                <border><left/></border>
              </borders>
            </styleSheet>
            """.utf8))

        styles.borders = XLBordersStorage()

        let xml = try String(decoding: styles.xmlDocument().data, as: UTF8.self)

        #expect(xml.contains(#"<borders count="0">"#) || xml.contains(#"<borders count="0"/>"#))
        #expect(!xml.contains("<border>"))
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
                styleFormatID: 0
            ),
            XLCellFormatRecord(
                numberFormatID: 14,
                fontID: 1,
                fillID: 2,
                borderID: 3,
                styleFormatID: 4,
                applyNumberFormat: true,
                applyFont: false
            ),
        ])
    }

    @Test func readsCellStyleFormatsFromCellStyleXfs() throws {
        let styles = try stylesFile(data: Data("""
            <styleSheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">
              <numFmts count="1"><numFmt numFmtId="164" formatCode="yyyy-mm-dd"/></numFmts>
              <fonts count="1"><font><b/></font></fonts>
              <fills count="1"><fill><patternFill patternType="solid"/></fill></fills>
              <borders count="1"><border><left style="thin"/></border></borders>
              <cellStyleXfs count="3">
                <xf numFmtId="0" fontId="0" fillId="0" borderId="0"/>
                <xf numFmtId="14" applyNumberFormat="1" applyAlignment="1"/>
                <xf numFmtId="164" applyNumberFormat="1"/>
              </cellStyleXfs>
            </styleSheet>
            """.utf8))

        #expect(styles.cellStyleFormats.records.count == 3)
        #expect(styles.cellStyleFormats.records[0].numberFormat == .builtin(id: 0))
        #expect(styles.cellStyleFormats.records[0].font == XLFont(bold: true))
        #expect(styles.cellStyleFormats.records[0].fill == .pattern(XLFill.Pattern(patternType: "solid")))
        #expect(styles.cellStyleFormats.records[0].border == XLBorder(left: XLBorder.Line(style: .thin)))
        #expect(styles.cellStyleFormats.records[1].numberFormat == .builtin(id: 14))
        #expect(styles.cellStyleFormats.records[1].font == nil)
        #expect(styles.cellStyleFormats.records[1].fill == nil)
        #expect(styles.cellStyleFormats.records[1].border == nil)
        #expect(styles.cellStyleFormats.records[2].numberFormat == .format("yyyy-mm-dd"))
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
                styleFormatID: 0,
                applyNumberFormat: true,
                applyFont: true
            ),
            XLCellFormatRecord(styleFormatID: 0, applyProtection: false),
        ])

        let xml = try String(decoding: styles.xmlDocument().data, as: UTF8.self)

        #expect(xml.contains(#"<numFmts count="1"><numFmt numFmtId="164" formatCode="yyyy-mm-dd"/></numFmts>"#))
        #expect(xml.contains(#"<opaqueStyle/>"#))
        #expect(xml.contains(#"<cellXfs count="2">"#))
        #expect(xml.contains(#"<xf numFmtId="164" fontId="1" fillId="2" borderId="3" xfId="0" applyNumberFormat="1" applyFont="1"/>"#))
        #expect(xml.contains(#"<xf xfId="0"/>"#))
        #expect(!xml.contains(#"applyProtection="0""#))
    }

    @Test func patchesCellStyleFormatsWithoutRemovingOtherStyleChildren() throws {
        let styles = try stylesFile(data: Data("""
            <styleSheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">
              <numFmts count="1"><numFmt numFmtId="164" formatCode="yyyy-mm-dd"/></numFmts>
              <cellStyleXfs count="1">
                <xf numFmtId="0"/>
              </cellStyleXfs>
              <opaqueStyle/>
            </styleSheet>
            """.utf8))
        let styleFormat = XLCellStyleFormatRef(numberFormat: .format("yyyy-mm-dd"))
        let styleFormatCopy = styleFormat
        let otherStyleFormat = XLCellStyleFormatRef(numberFormat: .format("yyyy-mm-dd"))

        styles.cellStyleFormats = XLCellStyleFormatRefsStorage(records: [
            styleFormat,
            styleFormatCopy,
            otherStyleFormat,
        ])

        let xml = try String(decoding: styles.xmlDocument().data, as: UTF8.self)

        #expect(styles.cellStyleFormats.records.count == 2)
        #expect(xml.contains(#"<numFmts count="1"><numFmt numFmtId="164" formatCode="yyyy-mm-dd"/></numFmts>"#))
        #expect(xml.contains(#"<opaqueStyle/>"#))
        #expect(xml.contains(#"<cellStyleXfs count="2">"#))
        #expect(xml.components(separatedBy: #"<xf numFmtId="164"/>"#).count == 3)
        #expect(!xml.contains(#"xfId="#))
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

    @Test func doesNotCreateCellStyleXfsWhenOriginalHasNoneAndCellStyleFormatsAreEmpty() throws {
        let styles = try stylesFile(data: Data("""
            <styleSheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">
              <opaqueStyle/>
            </styleSheet>
            """.utf8))

        let xml = try String(decoding: styles.xmlDocument().data, as: UTF8.self)

        #expect(!xml.contains("<cellStyleXfs"))
        #expect(xml.contains(#"<opaqueStyle/>"#))
    }

    @Test func preservesExistingCellStyleXfsTagWhenCellStyleFormatsBecomeEmpty() throws {
        let styles = try stylesFile(data: Data("""
            <styleSheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">
              <cellStyleXfs count="1">
                <xf numFmtId="0"/>
              </cellStyleXfs>
            </styleSheet>
            """.utf8))

        styles.cellStyleFormats = XLCellStyleFormatRefsStorage()

        let xml = try String(decoding: styles.xmlDocument().data, as: UTF8.self)

        #expect(xml.contains(#"<cellStyleXfs count="0">"#) || xml.contains(#"<cellStyleXfs count="0"/>"#))
        #expect(!xml.contains(#"<xf "#))
    }

    private func stylesFile(data: Data) throws -> XLStylesFile {
        try XLStylesFile(xmlDocument: XMLDocument(data: data))
    }
}
