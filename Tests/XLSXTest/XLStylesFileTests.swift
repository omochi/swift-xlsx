import Foundation
import OrderedCollections
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
        let styleStorage = try styleStorage(data: Data("""
            <styleSheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">
              <numFmts count="2">
                <numFmt numFmtId="165" formatCode="#,##0.000"/>
                <numFmt numFmtId="164" formatCode="yyyy-mm-dd"/>
              </numFmts>
            </styleSheet>
            """.utf8))

        #expect(Array(styleStorage.numberFormats) == [
            "yyyy-mm-dd",
            "#,##0.000",
        ])
    }

    @Test func patchesNumberFormatsWithoutRemovingOtherStyleChildren() throws {
        let parsed = try stylesAndStyleStorage(data: Data("""
            <styleSheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">
              <fonts count="1"><font/></fonts>
              <opaqueStyle/>
            </styleSheet>
            """.utf8))
        let styles = parsed.styles
        var styleStorage = parsed.styleStorage

        styleStorage.numberFormats = OrderedSet<String>([
            "yyyy-mm-dd",
            "#,##0.000",
        ])

        let xml = try String(decoding: styles.xmlDocument(styleStorage: styleStorage).data, as: UTF8.self)

        #expect(xml.contains(##"<numFmts count="2"><numFmt numFmtId="164" formatCode="yyyy-mm-dd"/><numFmt numFmtId="165" formatCode="#,##0.000"/></numFmts>"##))
        #expect(xml.contains(#"<fonts count="1"><font/></fonts>"#))
        #expect(xml.contains(#"<opaqueStyle/>"#))
    }

    @Test func readsFontsFromFontsElement() throws {
        let styleStorage = try styleStorage(data: Data("""
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

        #expect(Array(styleStorage.fonts) == [
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
        let styleStorage = XLStyleStorage(fonts: OrderedSet<XLFontRecord>([
            XLFontRecord(color: .rgb("FFFF0000")),
            XLFontRecord(color: .indexed(64)),
            XLFontRecord(color: .theme(4, tint: -0.25)),
            XLFontRecord(color: .auto),
        ]))
        let styles = XLStylesFile(styleStorage: styleStorage)

        let xml = try String(decoding: styles.xmlDocument(styleStorage: styleStorage).data, as: UTF8.self)

        #expect(xml.contains(#"<font><color rgb="FFFF0000"/></font>"#))
        #expect(xml.contains(#"<font><color indexed="64"/></font>"#))
        #expect(xml.contains(#"<font><color theme="4" tint="-0.25"/></font>"#))
        #expect(xml.contains(#"<font><color auto="1"/></font>"#))
    }

    @Test func patchesFontsWithoutRemovingOtherStyleChildren() throws {
        let parsed = try stylesAndStyleStorage(data: Data("""
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
        let styles = parsed.styles
        var styleStorage = parsed.styleStorage

        styleStorage.fonts = OrderedSet<XLFontRecord>([
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

        let xml = try String(decoding: styles.xmlDocument(styleStorage: styleStorage).data, as: UTF8.self)

        #expect(xml.contains(#"<numFmts count="1"><numFmt numFmtId="164" formatCode="yyyy-mm-dd"/></numFmts>"#))
        #expect(xml.contains(#"<fonts count="2">"#))
        #expect(xml.contains(#"<font><b/><condense/><extend/><outline/><shadow/><u val="single"/><sz val="12.0"/><color rgb="FFFF0000"/><name val="Arial"/><family val="2"/></font>"#))
        #expect(xml.contains(#"<font><i/><name val="Helvetica Neue"/></font>"#))
        #expect(xml.contains(#"<cellXfs count="1">"#))
    }

    @Test func preservesExistingFontsTagWhenFontsBecomeEmpty() throws {
        let parsed = try stylesAndStyleStorage(data: Data("""
            <styleSheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">
              <fonts count="1">
                <font><name val="Calibri"/></font>
              </fonts>
            </styleSheet>
            """.utf8))
        let styles = parsed.styles
        var styleStorage = parsed.styleStorage

        styleStorage.fonts = OrderedSet<XLFontRecord>()

        let xml = try String(decoding: styles.xmlDocument(styleStorage: styleStorage).data, as: UTF8.self)

        #expect(xml.contains(#"<fonts count="0">"#) || xml.contains(#"<fonts count="0"/>"#))
        #expect(!xml.contains("<font>"))
    }

    @Test func readsFillsFromFillsElement() throws {
        let styleStorage = try styleStorage(data: Data("""
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

        #expect(styleStorage.fills.count == 3)
        #expect(Array(styleStorage.fills.prefix(2)) == [
            XLFill.pattern(.none),
            XLFill.pattern(XLFill.Pattern(
                patternType: "solid",
                foregroundColor: .rgb("FFFFFF00"),
                backgroundColor: .indexed(64)
            )),
        ])
        if case let .gradient(xmlString) = styleStorage.fills[2] {
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
        let parsed = try stylesAndStyleStorage(data: Data("""
            <styleSheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">
              <fonts count="1"><font><name val="Calibri"/></font></fonts>
              <fills count="1">
                <fill><patternFill patternType="none"/></fill>
              </fills>
              <cellXfs count="1"><xf numFmtId="0"/></cellXfs>
            </styleSheet>
            """.utf8))
        let styles = parsed.styles
        var styleStorage = parsed.styleStorage

        styleStorage.fills = OrderedSet<XLFill>([
            .pattern(XLFill.Pattern(
                patternType: "solid",
                foregroundColor: .rgb("FFFFFF00"),
                backgroundColor: .indexed(64)
            )),
            .gradient(xmlString: #"<gradientFill degree="45"><stop position="0"><color rgb="FFFFFFFF"/></stop></gradientFill>"#),
        ])

        let xml = try String(decoding: styles.xmlDocument(styleStorage: styleStorage).data, as: UTF8.self)

        #expect(xml.contains(#"<fonts count="1"><font><name val="Calibri"/></font></fonts>"#))
        #expect(xml.contains(#"<fills count="2">"#))
        #expect(xml.contains(#"<fill><patternFill patternType="solid"><fgColor rgb="FFFFFF00"/><bgColor indexed="64"/></patternFill></fill>"#))
        #expect(xml.contains(#"<fill><gradientFill degree="45"><stop position="0"><color rgb="FFFFFFFF"/></stop></gradientFill></fill>"#))
        #expect(xml.contains(#"<cellXfs count="1"><xf numFmtId="0"/></cellXfs>"#))
    }

    @Test func preservesExistingFillsTagWhenFillsBecomeEmpty() throws {
        let parsed = try stylesAndStyleStorage(data: Data("""
            <styleSheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">
              <fills count="1">
                <fill><patternFill patternType="none"/></fill>
              </fills>
            </styleSheet>
            """.utf8))
        let styles = parsed.styles
        var styleStorage = parsed.styleStorage

        styleStorage.fills = OrderedSet<XLFill>()

        let xml = try String(decoding: styles.xmlDocument(styleStorage: styleStorage).data, as: UTF8.self)

        #expect(xml.contains(#"<fills count="0">"#) || xml.contains(#"<fills count="0"/>"#))
        #expect(!xml.contains("<fill>"))
    }

    @Test func readsBordersFromBordersElement() throws {
        let styleStorage = try styleStorage(data: Data("""
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

        #expect(Array(styleStorage.borders) == [
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
        let parsed = try stylesAndStyleStorage(data: Data("""
            <styleSheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">
              <fonts count="1"><font><name val="Calibri"/></font></fonts>
              <borders count="1">
                <border><left/></border>
              </borders>
              <cellXfs count="1"><xf borderId="0"/></cellXfs>
            </styleSheet>
            """.utf8))
        let styles = parsed.styles
        var styleStorage = parsed.styleStorage

        styleStorage.borders = OrderedSet<XLBorder>([
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

        let xml = try String(decoding: styles.xmlDocument(styleStorage: styleStorage).data, as: UTF8.self)

        #expect(xml.contains(#"<fonts count="1"><font><name val="Calibri"/></font></fonts>"#))
        #expect(xml.contains(#"<borders count="2">"#))
        #expect(xml.contains(#"<border><left style="thin"><color rgb="FFFF0000"/></left><right style="medium"/></border>"#))
        #expect(xml.contains(#"<border outline="0" diagonalUp="1" diagonalDown="1"><diagonal style="double"><color indexed="64"/></diagonal><vertical style="dashed"/><horizontal style="thick"/></border>"#))
        #expect(xml.contains(#"<cellXfs count="1"><xf borderId="0"/></cellXfs>"#))
    }

    @Test func preservesExistingBordersTagWhenBordersBecomeEmpty() throws {
        let parsed = try stylesAndStyleStorage(data: Data("""
            <styleSheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">
              <borders count="1">
                <border><left/></border>
              </borders>
            </styleSheet>
            """.utf8))
        let styles = parsed.styles
        var styleStorage = parsed.styleStorage

        styleStorage.borders = OrderedSet<XLBorder>()

        let xml = try String(decoding: styles.xmlDocument(styleStorage: styleStorage).data, as: UTF8.self)

        #expect(xml.contains(#"<borders count="0">"#) || xml.contains(#"<borders count="0"/>"#))
        #expect(!xml.contains("<border>"))
    }

    @Test func readsCellFormatsFromCellXfs() throws {
        let styleStorage = try styleStorage(data: Data("""
            <styleSheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">
              <cellXfs count="2">
                <xf numFmtId="0" fontId="0" fillId="0" borderId="0" xfId="0"/>
                <xf numFmtId="14" fontId="1" fillId="2" borderId="3" xfId="4" applyNumberFormat="1" applyFont="0"/>
              </cellXfs>
            </styleSheet>
            """.utf8))

        #expect(Array(styleStorage.cellFormats) == [
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
        let styleStorage = try styleStorage(data: Data("""
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

        #expect(styleStorage.cellStyleFormats.count == 3)
        #expect(styleStorage.cellStyleFormats[0].numberFormat == .builtin(id: 0))
        #expect(styleStorage.cellStyleFormats[0].font == XLFont(bold: true))
        #expect(styleStorage.cellStyleFormats[0].fill == .pattern(XLFill.Pattern(patternType: "solid")))
        #expect(styleStorage.cellStyleFormats[0].border == XLBorder(left: XLBorder.Line(style: .thin)))
        #expect(styleStorage.cellStyleFormats[1].numberFormat == .builtin(id: 14))
        #expect(styleStorage.cellStyleFormats[1].font == nil)
        #expect(styleStorage.cellStyleFormats[1].fill == nil)
        #expect(styleStorage.cellStyleFormats[1].border == nil)
        #expect(styleStorage.cellStyleFormats[2].numberFormat == .format("yyyy-mm-dd"))
    }

    @Test func readsCellStylesFromCellStyles() throws {
        let parsed = try stylesAndStyleStorage(data: Data("""
            <styleSheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" xmlns:rev="http://schemas.microsoft.com/office/spreadsheetml/2014/revision">
              <cellStyleXfs count="3">
                <xf numFmtId="0"/>
                <xf numFmtId="14"/>
                <xf numFmtId="49"/>
              </cellStyleXfs>
              <cellStyles count="3">
                <cellStyle name="スタイル 1" xfId="2" rev:uid="{0FC42694-F107-9C43-9C25-CD2D6A2DA94E}"/>
                <cellStyle name="どちらでもない" xfId="1" builtinId="28" hidden="1" customBuiltin="1" iLevel="2"/>
                <cellStyle name="標準" xfId="0" builtinId="0"/>
              </cellStyles>
            </styleSheet>
            """.utf8))
        let styles = parsed.styles

        #expect(styles.cellStyles.count == 3)
        let customStyle = styles.cellStyles[0]
        #expect(customStyle.name == "スタイル 1")
        #expect(customStyle.format?.numberFormat == .builtin(id: 49))
        #expect(customStyle.uniqueIdentifier == "{0FC42694-F107-9C43-9C25-CD2D6A2DA94E}")
        let neutralStyle = styles.cellStyles[1]
        #expect(neutralStyle.name == "どちらでもない")
        #expect(neutralStyle.format?.numberFormat == .builtin(id: 14))
        #expect(neutralStyle.builtinID == 28)
        #expect(neutralStyle.customBuiltin == true)
        #expect(neutralStyle.hidden == true)
        #expect(neutralStyle.outlineLevel == 2)
        let normalStyle = styles.cellStyles[2]
        #expect(normalStyle.name == "標準")
        #expect(normalStyle.format?.numberFormat == .builtin(id: 0))
        #expect(normalStyle.builtinID == 0)
    }

    @Test func patchesCellFormatsWithoutRemovingOtherStyleChildren() throws {
        let parsed = try stylesAndStyleStorage(data: Data("""
            <styleSheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">
              <numFmts count="1"><numFmt numFmtId="164" formatCode="yyyy-mm-dd"/></numFmts>
              <cellXfs count="1">
                <xf numFmtId="0" fontId="0" fillId="0" borderId="0" xfId="0"/>
              </cellXfs>
              <opaqueStyle/>
            </styleSheet>
            """.utf8))
        let styles = parsed.styles
        var styleStorage = parsed.styleStorage

        styleStorage.cellFormats = OrderedSet<XLCellFormatRecord>([
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

        let xml = try String(decoding: styles.xmlDocument(styleStorage: styleStorage).data, as: UTF8.self)

        #expect(xml.contains(#"<numFmts count="1"><numFmt numFmtId="164" formatCode="yyyy-mm-dd"/></numFmts>"#))
        #expect(xml.contains(#"<opaqueStyle/>"#))
        #expect(xml.contains(#"<cellXfs count="2">"#))
        #expect(xml.contains(#"<xf numFmtId="164" fontId="1" fillId="2" borderId="3" xfId="0" applyNumberFormat="1" applyFont="1"/>"#))
        #expect(xml.contains(#"<xf xfId="0"/>"#))
        #expect(!xml.contains(#"applyProtection="0""#))
    }

    @Test func patchesCellStyleFormatsWithoutRemovingOtherStyleChildren() throws {
        let parsed = try stylesAndStyleStorage(data: Data("""
            <styleSheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">
              <numFmts count="1"><numFmt numFmtId="164" formatCode="yyyy-mm-dd"/></numFmts>
              <cellStyleXfs count="1">
                <xf numFmtId="0"/>
              </cellStyleXfs>
              <opaqueStyle/>
            </styleSheet>
            """.utf8))
        let styles = parsed.styles
        var styleStorage = parsed.styleStorage
        let styleFormat = XLCellStyleFormatRef(numberFormat: .format("yyyy-mm-dd"))
        let styleFormatCopy = styleFormat
        let otherStyleFormat = XLCellStyleFormatRef(numberFormat: .format("yyyy-mm-dd"))

        styleStorage.cellStyleFormats = OrderedSet<XLCellStyleFormatRef>([
            styleFormat,
            styleFormatCopy,
            otherStyleFormat,
        ])

        let xml = try String(decoding: styles.xmlDocument(styleStorage: styleStorage).data, as: UTF8.self)
        let cellStyleXfsXML = try elementXML(named: "cellStyleXfs", in: xml)

        #expect(styleStorage.cellStyleFormats.count == 2)
        #expect(xml.contains(#"<numFmts count="1"><numFmt numFmtId="164" formatCode="yyyy-mm-dd"/></numFmts>"#))
        #expect(xml.contains(#"<opaqueStyle/>"#))
        #expect(xml.contains(#"<cellStyleXfs count="2">"#))
        #expect(xml.components(separatedBy: #"<xf numFmtId="164"/>"#).count == 3)
        #expect(!cellStyleXfsXML.contains(#"xfId="#))
    }

    @Test func patchesCellStylesWithoutRemovingOtherStyleChildren() throws {
        let parsed = try stylesAndStyleStorage(data: Data("""
            <styleSheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" xmlns:xr="http://schemas.microsoft.com/office/spreadsheetml/2014/revision">
              <cellStyleXfs count="1">
                <xf numFmtId="0"/>
              </cellStyleXfs>
              <cellStyles count="1">
                <cellStyle name="標準" xfId="0" builtinId="0"/>
              </cellStyles>
              <dxfs count="1">
                <dxf/>
              </dxfs>
              <tableStyles count="0">
              </tableStyles>
              <colors>
                <indexedColors/>
              </colors>
              <extLst>
                <ext uri="keep"/>
              </extLst>
              <opaqueStyle/>
            </styleSheet>
            """.utf8))
        let styles = parsed.styles
        var styleStorage = parsed.styleStorage
        let customFormat = XLCellStyleFormatRef(numberFormat: .builtin(id: 49))
        styleStorage.cellStyleFormats.append(customFormat)

        styles.cellStyles = [
            XLCellStyle(
                name: "スタイル 1",
                format: customFormat,
                uniqueIdentifier: "{0FC42694-F107-9C43-9C25-CD2D6A2DA94E}"
            ),
            XLCellStyle(name: "標準", format: styleStorage.cellStyleFormats[0], builtinID: 0),
        ]

        let xml = try String(decoding: styles.xmlDocument(styleStorage: styleStorage).data, as: UTF8.self)

        #expect(xml.contains(#"<opaqueStyle/>"#))
        #expect(xml.contains(#"<cellStyles count="2">"#))
        #expect(xml.contains(#"<cellStyle name="スタイル 1" xfId="1" xr:uid="{0FC42694-F107-9C43-9C25-CD2D6A2DA94E}"/>"#))
        #expect(xml.contains(#"<cellStyle name="標準" xfId="0" builtinId="0"/>"#))
    }

    @Test func styleStorageInitAddsInitialStyleRecordsWhenEmpty() throws {
        let styleStorage = XLStyleStorage()

        #expect(Array(styleStorage.fonts) == [XLFontRecord()])
        #expect(Array(styleStorage.fills) == [
            .pattern(.none),
            .pattern(.gray125),
        ])
        #expect(Array(styleStorage.borders) == [XLBorder()])
        #expect(styleStorage.cellStyleFormats.count == 1)
        #expect(Array(styleStorage.cellFormats) == [
            XLCellFormatRecord(
                numberFormatID: 0,
                fontID: 0,
                fillID: 0,
                borderID: 0,
                styleFormatID: 0
            )
        ])
    }

    @Test func stylesFileInitAddsInitialCellStyleWhenEmpty() throws {
        let styleStorage = XLStyleStorage()
        let styles = XLStylesFile(styleStorage: styleStorage)

        #expect(styles.cellStyles == [
            XLCellStyle(
                name: "Normal",
                format: styleStorage.cellStyleFormats[0],
                builtinID: 0
            )
        ])

        let xml = try String(decoding: styles.xmlDocument(styleStorage: styleStorage).data, as: UTF8.self)

        #expect(xml.contains(#"<cellStyleXfs count="1">"#))
        #expect(xml.contains(#"<cellStyles count="1">"#))
        #expect(xml.contains(#"<cellStyle name="Normal" xfId="0" builtinId="0"/>"#))
    }

    @Test func stylesFileInitKeepsExistingCellStyles() throws {
        let styleStorage = XLStyleStorage()
        let format = XLCellStyleFormatRef(numberFormat: .builtin(id: 49))
        let styles = XLStylesFile(styleStorage: styleStorage, cellStyles: [
            XLCellStyle(
                name: "スタイル 1",
                format: format,
                uniqueIdentifier: "{0FC42694-F107-9C43-9C25-CD2D6A2DA94E}"
            )
        ])

        let xml = try String(decoding: styles.xmlDocument(styleStorage: styleStorage).data, as: UTF8.self)

        #expect(styles.cellStyles.count == 1)
        #expect(styles.cellStyles[0] == XLCellStyle(
            name: "スタイル 1",
            format: format,
            uniqueIdentifier: "{0FC42694-F107-9C43-9C25-CD2D6A2DA94E}"
        ))
        #expect(xml.contains(#"<cellStyle name="スタイル 1" xr:uid="{0FC42694-F107-9C43-9C25-CD2D6A2DA94E}"/>"#))
    }

    @Test func stylesFileCollectStyleRegistersCellStyleFormats() throws {
        var styleStorage = XLStyleStorage()
        let format = XLCellStyleFormatRef(numberFormat: .format("yyyy-mm-dd"))
        let styles = XLStylesFile(
            styleStorage: styleStorage,
            cellStyles: [XLCellStyle(name: "日付", format: format)]
        )

        styles.collectStyle(styleStorage: &styleStorage)

        #expect(styleStorage.numberFormats.firstIndex(of: "yyyy-mm-dd") != nil)
        #expect(styleStorage.cellStyleFormats.firstIndex(of: format) != nil)
    }

    @Test func createsInitialCellXfsWhenOriginalHasNone() throws {
        let parsed = try stylesAndStyleStorage(data: Data("""
            <styleSheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">
              <opaqueStyle/>
            </styleSheet>
            """.utf8))

        let xml = try String(decoding: parsed.styles.xmlDocument(styleStorage: parsed.styleStorage).data, as: UTF8.self)

        #expect(xml.contains(#"<cellXfs count="1"><xf numFmtId="0" fontId="0" fillId="0" borderId="0" xfId="0"/></cellXfs>"#))
        #expect(xml.contains(#"<opaqueStyle/>"#))
    }

    @Test func preservesExistingCellXfsTagWhenCellFormatsBecomeEmpty() throws {
        let parsed = try stylesAndStyleStorage(data: Data("""
            <styleSheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">
              <cellXfs count="1">
                <xf numFmtId="0"/>
              </cellXfs>
            </styleSheet>
            """.utf8))
        let styles = parsed.styles
        var styleStorage = parsed.styleStorage

        styleStorage.cellFormats = OrderedSet<XLCellFormatRecord>()

        let xml = try String(decoding: styles.xmlDocument(styleStorage: styleStorage).data, as: UTF8.self)
        let cellXfsXML = try elementXML(named: "cellXfs", in: xml)

        #expect(xml.contains(#"<cellXfs count="0">"#) || xml.contains(#"<cellXfs count="0"/>"#))
        #expect(!cellXfsXML.contains(#"<xf "#))
    }

    @Test func createsInitialCellStyleXfsWhenOriginalHasNone() throws {
        let parsed = try stylesAndStyleStorage(data: Data("""
            <styleSheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">
              <opaqueStyle/>
            </styleSheet>
            """.utf8))

        let xml = try String(decoding: parsed.styles.xmlDocument(styleStorage: parsed.styleStorage).data, as: UTF8.self)

        #expect(xml.contains(#"<cellStyleXfs count="1"><xf numFmtId="0" fontId="0" fillId="0" borderId="0"/></cellStyleXfs>"#))
        #expect(xml.contains(#"<opaqueStyle/>"#))
    }

    @Test func createsInitialCellStylesWhenOriginalHasNone() throws {
        let parsed = try stylesAndStyleStorage(data: Data("""
            <styleSheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">
              <opaqueStyle/>
            </styleSheet>
            """.utf8))

        let xml = try String(decoding: parsed.styles.xmlDocument(styleStorage: parsed.styleStorage).data, as: UTF8.self)

        #expect(xml.contains(#"<cellStyles count="1"><cellStyle name="Normal" xfId="0" builtinId="0"/></cellStyles>"#))
        #expect(xml.contains(#"<opaqueStyle/>"#))
    }

    @Test func doesNotCreateCellStylesWhenUserClearsCellStylesAndOriginalHasNone() throws {
        let styleStorage = XLStyleStorage()
        let styles = XLStylesFile(styleStorage: styleStorage)

        styles.cellStyles = []

        let xml = try String(decoding: styles.xmlDocument(styleStorage: styleStorage).data, as: UTF8.self)

        #expect(!xml.contains("<cellStyles"))
    }

    @Test func preservesExistingCellStyleXfsTagWhenCellStyleFormatsBecomeEmpty() throws {
        let parsed = try stylesAndStyleStorage(data: Data("""
            <styleSheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">
              <cellStyleXfs count="1">
                <xf numFmtId="0"/>
              </cellStyleXfs>
            </styleSheet>
            """.utf8))
        let styles = parsed.styles
        var styleStorage = parsed.styleStorage

        styleStorage.cellStyleFormats = OrderedSet<XLCellStyleFormatRef>()

        let xml = try String(decoding: styles.xmlDocument(styleStorage: styleStorage).data, as: UTF8.self)
        let cellStyleXfsXML = try elementXML(named: "cellStyleXfs", in: xml)

        #expect(xml.contains(#"<cellStyleXfs count="0">"#) || xml.contains(#"<cellStyleXfs count="0"/>"#))
        #expect(!cellStyleXfsXML.contains(#"<xf "#))
    }

    @Test func preservesExistingCellStylesTagWhenCellStylesBecomeEmpty() throws {
        let parsed = try stylesAndStyleStorage(data: Data("""
            <styleSheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">
              <cellStyles count="1">
                <cellStyle name="標準" xfId="0" builtinId="0"/>
              </cellStyles>
            </styleSheet>
            """.utf8))
        let styles = parsed.styles

        styles.cellStyles = []

        let xml = try String(decoding: styles.xmlDocument(styleStorage: parsed.styleStorage).data, as: UTF8.self)

        #expect(xml.contains(#"<cellStyles count="0">"#) || xml.contains(#"<cellStyles count="0"/>"#))
        #expect(!xml.contains(#"<cellStyle "#))
    }

    @Test func insertsMissingStyleSheetChildrenInStylesheetOrder() throws {
        let cellStyleElement = XLSX.XMLElement(name: XMLName(name: "cellStyle"))
        cellStyleElement.setAttribute(name: "name", value: "標準")
        cellStyleElement.setAttribute(name: "xfId", value: "0")
        cellStyleElement.setAttribute(name: "builtinId", value: "0")

        let cellStylesElement = XLSX.XMLElement(
            name: XMLName(name: "cellStyles"),
            children: [cellStyleElement]
        )
        cellStylesElement.setAttribute(name: "count", value: "1")

        let styleSheetElement = XLSX.XMLElement(
            name: XMLName(name: "styleSheet"),
            children: [
                cellStylesElement,
                XLSX.XMLElement(name: XMLName(name: "dxfs")),
                XLSX.XMLElement(name: XMLName(name: "tableStyles")),
                XLSX.XMLElement(name: XMLName(name: "colors")),
                XLSX.XMLElement(name: XMLName(name: "extLst")),
                XLSX.XMLElement(name: XMLName(name: "opaqueStyle")),
            ]
        )
        styleSheetElement.ensureNamespace(uri: .spreadsheet)
        let styles = try XLStylesFile(xmlDocument: XMLDocument(children: [styleSheetElement]))
        var styleStorage = XLStyleStorage()

        styleStorage.cellStyleFormats = OrderedSet<XLCellStyleFormatRef>([
            XLCellStyleFormatRef(numberFormat: .builtin(id: 0))
        ])
        styleStorage.cellFormats = OrderedSet<XLCellFormatRecord>([
            XLCellFormatRecord(styleFormatID: 0)
        ])

        let xml = try String(decoding: styles.xmlDocument(styleStorage: styleStorage).data, as: UTF8.self)
        let cellStyleXfsIndex = try #require(xml.range(of: "<cellStyleXfs")?.lowerBound)
        let cellXfsIndex = try #require(xml.range(of: "<cellXfs")?.lowerBound)
        let cellStylesIndex = try #require(xml.range(of: "<cellStyles")?.lowerBound)
        let dxfsIndex = try #require(xml.range(of: "<dxfs")?.lowerBound)
        let tableStylesIndex = try #require(xml.range(of: "<tableStyles")?.lowerBound)
        let colorsIndex = try #require(xml.range(of: "<colors")?.lowerBound)
        let extListIndex = try #require(xml.range(of: "<extLst")?.lowerBound)
        let opaqueStyleIndex = try #require(xml.range(of: "<opaqueStyle")?.lowerBound)

        #expect(cellStyleXfsIndex < cellXfsIndex)
        #expect(cellXfsIndex < cellStylesIndex)
        #expect(cellStylesIndex < dxfsIndex)
        #expect(dxfsIndex < tableStylesIndex)
        #expect(tableStylesIndex < colorsIndex)
        #expect(colorsIndex < extListIndex)
        #expect(extListIndex < opaqueStyleIndex)
    }

    private func stylesFile(data: Data) throws -> XLStylesFile {
        try XLStylesFile(xmlDocument: XMLDocument(data: data))
    }

    private func styleStorage(data: Data) throws -> XLStyleStorage {
        try XLStyleStorage(xmlDocument: XMLDocument(data: data))
    }

    private func stylesAndStyleStorage(data: Data) throws -> (styles: XLStylesFile, styleStorage: XLStyleStorage) {
        let document = try XMLDocument(data: data)
        let styleStorage = try XLStyleStorage(xmlDocument: document)
        return (
            styles: try XLStylesFile(xmlDocument: document, styleStorage: styleStorage),
            styleStorage: styleStorage
        )
    }

    private func elementXML(named name: String, in xml: String) throws -> String {
        let startRange = try #require(xml.range(of: "<\(name)"))
        let searchRange = startRange.lowerBound..<xml.endIndex

        if let endRange = xml.range(of: "</\(name)>", range: searchRange) {
            return String(xml[startRange.lowerBound..<endRange.upperBound])
        }

        let endIndex = try #require(xml[startRange.lowerBound...].firstIndex(of: ">"))
        return String(xml[startRange.lowerBound...endIndex])
    }
}
