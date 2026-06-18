import class Foundation.Bundle
import struct Foundation.Data
import class Foundation.FileManager
import struct Foundation.UUID
import Testing
import XLSX
import XLSXXML

@Suite
struct XLDocumentTests {
    @Test func savesOpenedWorkbookThroughRelationships() throws {
        let sourceURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("swift-xlsx-tests-\(UUID().uuidString)")
            .appendingPathExtension("xlsx")
        let destinationURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("swift-xlsx-tests-\(UUID().uuidString)")
            .appendingPathExtension("xlsx")
        defer {
            try? FileManager.default.removeItem(at: sourceURL)
            try? FileManager.default.removeItem(at: destinationURL)
        }

        try Data(contentsOf: try #require(Bundle.module.url(forResource: "simple", withExtension: "xlsx"))).write(to: sourceURL)

        let document = try XLDocument.open(url: sourceURL)
        try document.save(to: destinationURL)

        let package = try OPCPackage(data: Data(contentsOf: destinationURL))
        let worksheetXML = try String(decoding: #require(package.data(at: OPCFilePath(string: "/xl/worksheets/sheet1.xml"))), as: UTF8.self)
        let sharedStringsXML = try String(decoding: #require(package.data(at: OPCFilePath(string: "/xl/sharedStrings.xml"))), as: UTF8.self)

        #expect(worksheetXML.contains("<c r=\"A1\" t=\"s\">"))
        #expect(worksheetXML.contains("<v>0</v>"))
        #expect(sharedStringsXML.contains("<t>A</t>"))
    }

    @Test func opensPlainSharedStringCellsAsStringValues() throws {
        let document = try XLDocument.open(url: try #require(Bundle.module.url(forResource: "simple", withExtension: "xlsx")))
        let worksheet = try #require(document.workbook.worksheets.first)

        #expect(worksheet.existingCell(row: 1, column: 1)?.value == .string("A"))
    }

    @Test func opensCellFormatsThroughDocumentStylePool() throws {
        var package = OPCPackage()
        try package.insertFile(
            data: Data("""
                <Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
                  <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
                  <Default Extension="xml" ContentType="application/xml"/>
                  <Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>
                  <Override PartName="/xl/worksheets/sheet1.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>
                  <Override PartName="/xl/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml"/>
                </Types>
                """.utf8),
            at: OPCFilePath(string: "/[Content_Types].xml")
        )
        try package.insertFile(
            data: Data("""
                <Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
                  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/>
                </Relationships>
                """.utf8),
            at: try OPCRelsFile.path(for: .packageRoot)
        )
        try package.insertFile(
            data: Data("""
                <workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">
                  <sheets><sheet name="Sheet1" sheetId="1" r:id="rId1"/></sheets>
                </workbook>
                """.utf8),
            at: OPCFilePath(string: "/xl/workbook.xml")
        )
        try package.insertFile(
            data: Data("""
                <Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
                  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet1.xml"/>
                  <Relationship Id="rId2" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/>
                </Relationships>
                """.utf8),
            at: OPCFilePath(string: "/xl/_rels/workbook.xml.rels")
        )
        try package.insertFile(
            data: Data("""
                <worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">
                  <sheetData><row r="1"><c r="A1" s="1"><v>42</v></c><c r="B1" s="2"><v>45825</v></c></row></sheetData>
                </worksheet>
                """.utf8),
            at: OPCFilePath(string: "/xl/worksheets/sheet1.xml")
        )
        let stylesData = Data("""
                <styleSheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">
                  <numFmts count="1"><numFmt numFmtId="164" formatCode="yyyy-mm-dd"/></numFmts>
                  <borders count="1">
                    <border><left style="thin"><color rgb="FFFF0000"/></left></border>
                  </borders>
                  <cellXfs count="3">
                    <xf numFmtId="0"/>
                    <xf numFmtId="14" borderId="0" applyNumberFormat="1"/>
                    <xf numFmtId="164" applyNumberFormat="1"/>
                  </cellXfs>
                </styleSheet>
                """.utf8)
        try package.insertFile(
            data: stylesData,
            at: OPCFilePath(string: "/xl/styles.xml")
        )

        let document = try XLDocument(opcPackage: package)
        let worksheet = try #require(document.workbook.worksheets.first)
        let cell = try #require(worksheet.existingCell(row: 1, column: 1))
        let customFormatCell = try #require(worksheet.existingCell(row: 1, column: 2))
        let styleStorage = try XLStyleStorage(xmlDocument: XMLDocument(data: stylesData))
        let storedRecord = try #require(
            styleStorage.cellFormats.indices.contains(1) ? styleStorage.cellFormats[1] : nil
        )
        let border = XLBorder(left: XLBorder.Line(style: .thin, color: .rgb("FFFF0000")))

        #expect(cell.format == XLCellFormat(
            numberFormat: .builtin(id: 14),
            border: border,
            applyNumberFormat: true,
            applyBorder: false
        ))
        #expect(cell.format == XLCellFormat(
            record: storedRecord,
            numberFormats: styleStorage.numberFormats,
            fonts: styleStorage.fonts,
            fills: styleStorage.fills,
            borders: styleStorage.borders,
            cellStyleFormats: styleStorage.cellStyleFormats
        ))
        #expect(customFormatCell.format == XLCellFormat(
            numberFormat: .format("yyyy-mm-dd"),
            applyNumberFormat: true
        ))
    }

    @Test func opensColumnFormatsThroughDocumentStylePool() throws {
        var package = OPCPackage()
        try package.insertFile(
            data: Data("""
                <Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
                  <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
                  <Default Extension="xml" ContentType="application/xml"/>
                  <Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>
                  <Override PartName="/xl/worksheets/sheet1.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>
                  <Override PartName="/xl/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml"/>
                </Types>
                """.utf8),
            at: OPCFilePath(string: "/[Content_Types].xml")
        )
        try package.insertFile(
            data: Data("""
                <Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
                  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/>
                </Relationships>
                """.utf8),
            at: try OPCRelsFile.path(for: .packageRoot)
        )
        try package.insertFile(
            data: Data("""
                <workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">
                  <sheets><sheet name="Sheet1" sheetId="1" r:id="rId1"/></sheets>
                </workbook>
                """.utf8),
            at: OPCFilePath(string: "/xl/workbook.xml")
        )
        try package.insertFile(
            data: Data("""
                <Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
                  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet1.xml"/>
                  <Relationship Id="rId2" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/>
                </Relationships>
                """.utf8),
            at: OPCFilePath(string: "/xl/_rels/workbook.xml.rels")
        )
        try package.insertFile(
            data: Data("""
                <worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">
                  <cols><col min="2" max="2" style="1"/></cols>
                  <sheetData/>
                </worksheet>
                """.utf8),
            at: OPCFilePath(string: "/xl/worksheets/sheet1.xml")
        )
        try package.insertFile(
            data: Data("""
                <styleSheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">
                  <cellXfs count="2">
                    <xf numFmtId="0"/>
                    <xf numFmtId="14" applyNumberFormat="1"/>
                  </cellXfs>
                </styleSheet>
                """.utf8),
            at: OPCFilePath(string: "/xl/styles.xml")
        )

        let document = try XLDocument(opcPackage: package)
        let worksheet = try #require(document.workbook.worksheets.first)

        #expect(worksheet.existingColumn(2)?.format == XLCellFormat(
            numberFormat: .builtin(id: 14),
            applyNumberFormat: true
        ))
    }

    @Test func removesUnusedCellFormatsWhenSaving() throws {
        var package = OPCPackage()
        try package.insertFile(
            data: Data("""
                <Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
                  <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
                  <Default Extension="xml" ContentType="application/xml"/>
                  <Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>
                  <Override PartName="/xl/worksheets/sheet1.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>
                  <Override PartName="/xl/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml"/>
                </Types>
                """.utf8),
            at: OPCFilePath(string: "/[Content_Types].xml")
        )
        try package.insertFile(
            data: Data("""
                <Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
                  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/>
                </Relationships>
                """.utf8),
            at: try OPCRelsFile.path(for: .packageRoot)
        )
        try package.insertFile(
            data: Data("""
                <workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">
                  <sheets><sheet name="Sheet1" sheetId="1" r:id="rId1"/></sheets>
                </workbook>
                """.utf8),
            at: OPCFilePath(string: "/xl/workbook.xml")
        )
        try package.insertFile(
            data: Data("""
                <Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
                  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet1.xml"/>
                  <Relationship Id="rId2" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/>
                </Relationships>
                """.utf8),
            at: OPCFilePath(string: "/xl/_rels/workbook.xml.rels")
        )
        try package.insertFile(
            data: Data("""
                <worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">
                  <sheetData><row r="1"><c r="A1" s="1"><v>42</v></c></row></sheetData>
                </worksheet>
                """.utf8),
            at: OPCFilePath(string: "/xl/worksheets/sheet1.xml")
        )
        try package.insertFile(
            data: Data("""
                <styleSheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">
                  <cellXfs count="2">
                    <xf numFmtId="0"/>
                    <xf numFmtId="14" applyNumberFormat="1"/>
                  </cellXfs>
                </styleSheet>
                """.utf8),
            at: OPCFilePath(string: "/xl/styles.xml")
        )

        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("swift-xlsx-tests-\(UUID().uuidString)")
            .appendingPathExtension("xlsx")
        defer {
            try? FileManager.default.removeItem(at: url)
        }

        let document = try XLDocument(opcPackage: package)
        try document.save(to: url)

        let savedPackage = try OPCPackage(data: Data(contentsOf: url))
        let worksheetXML = try String(
            decoding: #require(savedPackage.data(at: OPCFilePath(string: "/xl/worksheets/sheet1.xml"))),
            as: UTF8.self
        )
        let stylesXML = try String(
            decoding: #require(savedPackage.data(at: OPCFilePath(string: "/xl/styles.xml"))),
            as: UTF8.self
        )

        #expect(worksheetXML.contains(#"<c r="A1" s="1"><v>42</v></c>"#))
        #expect(stylesXML.contains(#"<cellXfs count="2">"#))
        #expect(stylesXML.contains(#"<xf numFmtId="0" fontId="0" fillId="0" borderId="0" xfId="0"/>"#))
        #expect(stylesXML.contains(#"<xf numFmtId="14" applyNumberFormat="1"/>"#))
        #expect(!stylesXML.contains(#"numFmtId="99""#))
    }

    @Test func savesCellFormatsThroughDocumentStylePool() throws {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("swift-xlsx-tests-\(UUID().uuidString)")
            .appendingPathExtension("xlsx")
        defer {
            try? FileManager.default.removeItem(at: url)
        }

        let document = XLDocument()
        let worksheet = try #require(document.workbook.worksheets.first)
        let styleFormat = XLCellStyleFormatRef(
            numberFormat: .builtin(id: 0),
            font: XLFont(),
            fill: .pattern(.none),
            border: XLBorder()
        )
        let format = XLCellFormat(
            numberFormat: .builtin(id: 14),
            font: XLFont(bold: true, size: 12, name: "Arial"),
            fill: .pattern(XLFill.Pattern(
                patternType: .solid,
                foregroundColor: .rgb("FFFFFF00"),
                backgroundColor: .indexed(64)
            )),
            border: XLBorder(
                left: XLBorder.Line(style: .thin, color: .rgb("FFFF0000")),
                right: XLBorder.Line(style: .medium)
            ),
            styleFormat: styleFormat,
            applyNumberFormat: true
        )
        worksheet.cell(row: 1, column: 1).value = .number(42)
        worksheet.cell(row: 1, column: 1).format = format
        worksheet.cell(row: 1, column: 2).value = .number(43)
        worksheet.cell(row: 1, column: 2).format = format

        try document.save(to: url)

        let package = try OPCPackage(data: Data(contentsOf: url))
        let worksheetXML = try String(
            decoding: #require(package.data(at: OPCFilePath(string: "/xl/worksheets/sheet1.xml"))),
            as: UTF8.self
        )
        let stylesXML = try String(
            decoding: #require(package.data(at: OPCFilePath(string: "/xl/styles.xml"))),
            as: UTF8.self
        )

        #expect(worksheetXML.contains(#"<c r="A1" s="1"><v>42</v></c>"#))
        #expect(worksheetXML.contains(#"<c r="B1" s="1"><v>43</v></c>"#))
        #expect(stylesXML.contains(#"<fonts count="2">"#))
        #expect(stylesXML.contains(#"<font/>"#))
        #expect(stylesXML.contains(#"<font><b/><sz val="12.0"/><name val="Arial"/></font>"#))
        #expect(stylesXML.contains(#"<fills count="3">"#))
        #expect(stylesXML.contains(#"<fill><patternFill patternType="none"/></fill>"#))
        #expect(stylesXML.contains(#"<fill><patternFill patternType="gray125"/></fill>"#))
        #expect(stylesXML.contains(#"<fill><patternFill patternType="solid"><fgColor rgb="FFFFFF00"/><bgColor indexed="64"/></patternFill></fill>"#))
        #expect(stylesXML.contains(#"<borders count="2">"#))
        #expect(stylesXML.contains(#"<border/>"#))
        #expect(stylesXML.contains(#"<border><left style="thin"><color rgb="FFFF0000"/></left><right style="medium"/></border>"#))
        #expect(stylesXML.contains(#"<cellStyleXfs count="2">"#))
        #expect(stylesXML.contains(#"<cellXfs count="2">"#))
        #expect(stylesXML.contains(#"<xf numFmtId="0" fontId="0" fillId="0" borderId="0" xfId="0"/>"#))
        #expect(stylesXML.contains(#"<xf numFmtId="14" fontId="1" fillId="2" borderId="1" xfId="1" applyNumberFormat="1" applyFont="1" applyBorder="1"/>"#))
    }

    @Test func savesColumnFormatsThroughDocumentStylePool() throws {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("swift-xlsx-tests-\(UUID().uuidString)")
            .appendingPathExtension("xlsx")
        defer {
            try? FileManager.default.removeItem(at: url)
        }

        let document = XLDocument()
        let worksheet = try #require(document.workbook.worksheets.first)
        worksheet.column(2).format = XLCellFormat(numberFormat: .builtin(id: 14))
        worksheet.column(3).format = XLCellFormat(numberFormat: .builtin(id: 14))

        try document.save(to: url)

        let package = try OPCPackage(data: Data(contentsOf: url))
        let worksheetXML = try String(
            decoding: #require(package.data(at: OPCFilePath(string: "/xl/worksheets/sheet1.xml"))),
            as: UTF8.self
        )
        let stylesXML = try String(
            decoding: #require(package.data(at: OPCFilePath(string: "/xl/styles.xml"))),
            as: UTF8.self
        )

        #expect(worksheetXML.contains(#"<cols><col min="2" max="3" style="1"/></cols>"#))
        #expect(stylesXML.contains(#"<cellXfs count="2">"#))
        #expect(stylesXML.contains(#"<xf numFmtId="14" applyNumberFormat="1"/>"#))
    }

    @Test func savesCustomNumberFormatsThroughDocumentStylePool() throws {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("swift-xlsx-tests-\(UUID().uuidString)")
            .appendingPathExtension("xlsx")
        defer {
            try? FileManager.default.removeItem(at: url)
        }

        let document = XLDocument()
        let worksheet = try #require(document.workbook.worksheets.first)
        let format = XLCellFormat(numberFormat: .format("yyyy-mm-dd"))
        worksheet.cell(row: 1, column: 1).value = .number(45825)
        worksheet.cell(row: 1, column: 1).format = format
        worksheet.cell(row: 1, column: 2).value = .number(45826)
        worksheet.cell(row: 1, column: 2).format = format

        try document.save(to: url)

        let package = try OPCPackage(data: Data(contentsOf: url))
        let worksheetXML = try String(
            decoding: #require(package.data(at: OPCFilePath(string: "/xl/worksheets/sheet1.xml"))),
            as: UTF8.self
        )
        let stylesXML = try String(
            decoding: #require(package.data(at: OPCFilePath(string: "/xl/styles.xml"))),
            as: UTF8.self
        )

        #expect(worksheetXML.contains(#"<c r="A1" s="1"><v>45825</v></c>"#))
        #expect(worksheetXML.contains(#"<c r="B1" s="1"><v>45826</v></c>"#))
        #expect(stylesXML.contains(#"<numFmts count="1"><numFmt numFmtId="164" formatCode="yyyy-mm-dd"/></numFmts>"#))
        #expect(stylesXML.contains(#"<cellXfs count="2">"#))
        #expect(stylesXML.contains(#"<xf numFmtId="164" applyNumberFormat="1"/>"#))
    }

    @Test func rebuildsSharedStringsFromEditedCells() throws {
        let sourceURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("swift-xlsx-tests-\(UUID().uuidString)")
            .appendingPathExtension("xlsx")
        let destinationURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("swift-xlsx-tests-\(UUID().uuidString)")
            .appendingPathExtension("xlsx")
        defer {
            try? FileManager.default.removeItem(at: sourceURL)
            try? FileManager.default.removeItem(at: destinationURL)
        }

        try Data(contentsOf: try #require(Bundle.module.url(forResource: "simple", withExtension: "xlsx"))).write(to: sourceURL)

        let document = try XLDocument.open(url: sourceURL)
        let worksheet = try #require(document.workbook.worksheets.first)
        worksheet.cell(row: 1, column: 1).value = .string("B")
        try document.save(to: destinationURL)

        let package = try OPCPackage(data: Data(contentsOf: destinationURL))
        let worksheetXML = try String(decoding: #require(package.data(at: OPCFilePath(string: "/xl/worksheets/sheet1.xml"))), as: UTF8.self)
            .replacingOccurrences(of: "\n", with: "")
            .replacingOccurrences(of: " ", with: "")
        let sharedStringsXML = try String(decoding: #require(package.data(at: OPCFilePath(string: "/xl/sharedStrings.xml"))), as: UTF8.self)

        #expect(worksheetXML.contains(#"<cr="A1"t="s"><v>0</v></c>"#))
        #expect(sharedStringsXML.contains(#"<t>B</t>"#))
        #expect(!sharedStringsXML.contains(#"<t>A</t>"#))
    }

    @Test func opensWorksheetsIntoWorkbookScope() throws {
        let document = try XLDocument.open(url: try #require(Bundle.module.url(forResource: "simple", withExtension: "xlsx")))

        let worksheet = try #require(document.package.workbook.file.worksheetByID[1])
        #expect(worksheet.path.description == "/xl/worksheets/sheet1.xml")
    }

    @Test func savesDefaultStylesRelationshipContentTypeAndPart() throws {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("swift-xlsx-tests-\(UUID().uuidString)")
            .appendingPathExtension("xlsx")
        defer {
            try? FileManager.default.removeItem(at: url)
        }

        let document = XLDocument()
        try document.save(to: url)

        let package = try OPCPackage(data: Data(contentsOf: url))
        let stylesPath = try OPCFilePath(string: "/xl/styles.xml")
        let workbookRelsPath = try OPCFilePath(string: "/xl/_rels/workbook.xml.rels")
        let contentTypesPath = try OPCFilePath(string: "/[Content_Types].xml")
        let workbookRels = try #require(try package.fileWithPath(OPCRelsFile.self, at: workbookRelsPath, read: OPCRelsFile.init(xmlDocument:)))
        let contentTypes = try #require(try package.fileWithPath(OPCContentTypesFile.self, at: contentTypesPath, read: OPCContentTypesFile.init(xmlDocument:)))

        let stylesXML = try String(decoding: #require(package.data(at: stylesPath)), as: UTF8.self)
        #expect(stylesXML.contains(#"<fonts count="1"><font/></fonts>"#))
        #expect(stylesXML.contains(#"<fills count="2"><fill><patternFill patternType="none"/></fill><fill><patternFill patternType="gray125"/></fill></fills>"#))
        #expect(stylesXML.contains(#"<borders count="1"><border/></borders>"#))
        #expect(stylesXML.contains(#"<cellStyleXfs count="1"><xf numFmtId="0" fontId="0" fillId="0" borderId="0"/></cellStyleXfs>"#))
        #expect(stylesXML.contains(#"<cellStyles count="1"><cellStyle name="Normal" xfId="0" builtinId="0"/></cellStyles>"#))
        #expect(stylesXML.contains(#"<cellXfs count="1"><xf numFmtId="0" fontId="0" fillId="0" borderId="0" xfId="0"/></cellXfs>"#))
        let cellStyleXfsIndex = try #require(stylesXML.range(of: "<cellStyleXfs")?.lowerBound)
        let cellXfsIndex = try #require(stylesXML.range(of: "<cellXfs")?.lowerBound)
        let cellStylesIndex = try #require(stylesXML.range(of: "<cellStyles")?.lowerBound)
        #expect(cellStyleXfsIndex < cellXfsIndex)
        #expect(cellXfsIndex < cellStylesIndex)
        #expect(workbookRels.file.relationships.contains {
            $0.type == XMLNamespaceURI.styles.string &&
            $0.target == "styles.xml"
        })
        #expect(contentTypes.file.overrides[stylesPath] == OPCContentTypes.styles)
    }

    @Test func preservesOpenedEmptyStylesRelationshipContentTypeAndPart() throws {
        var package = try OPCPackage(data: Data(
            contentsOf: try #require(Bundle.module.url(forResource: "simple", withExtension: "xlsx"))
        ))
        let stylesPath = try OPCFilePath(string: "/xl/styles.xml")
        let workbookRelsPath = try OPCFilePath(string: "/xl/_rels/workbook.xml.rels")
        try package.insertFile(
            data: Data("""
                <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
                <Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
                  <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
                  <Default Extension="xml" ContentType="application/xml"/>
                  <Override PartName="/xl/sharedStrings.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sharedStrings+xml"/>
                  <Override PartName="/xl/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml"/>
                  <Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>
                  <Override PartName="/xl/worksheets/sheet1.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>
                </Types>
                """.utf8),
            at: OPCFilePath(string: "/[Content_Types].xml")
        )
        try package.insertFile(
            data: Data("""
                <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
                <Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
                  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet1.xml"/>
                  <Relationship Id="rId2" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/sharedStrings" Target="sharedStrings.xml"/>
                  <Relationship Id="rId3" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/>
                </Relationships>
                """.utf8),
            at: workbookRelsPath
        )
        try package.insertFile(
            data: Data("""
                <styleSheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main"/>
                """.utf8),
            at: stylesPath
        )

        let destinationURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("swift-xlsx-tests-\(UUID().uuidString)")
            .appendingPathExtension("xlsx")
        defer {
            try? FileManager.default.removeItem(at: destinationURL)
        }

        let document = try XLDocument(opcPackage: package)
        try document.save(to: destinationURL)

        let savedPackage = try OPCPackage(data: Data(contentsOf: destinationURL))
        let savedWorkbookRels = try #require(try savedPackage.fileWithPath(OPCRelsFile.self, at: workbookRelsPath, read: OPCRelsFile.init(xmlDocument:)))
        let savedContentTypes = try #require(try savedPackage.fileWithPath(
            OPCContentTypesFile.self,
            at: OPCFilePath(string: "/[Content_Types].xml"),
            read: OPCContentTypesFile.init(xmlDocument:)
        ))

        #expect(savedPackage.data(at: stylesPath) != nil)
        #expect(savedWorkbookRels.file.relationships.contains {
            $0.type == XMLNamespaceURI.styles.string &&
            $0.target == "styles.xml"
        })
        #expect(savedContentTypes.file.overrides[stylesPath] == OPCContentTypes.styles)
    }

    @Test func savesSharedStringsAndStylesAtStoredPaths() throws {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("swift-xlsx-tests-\(UUID().uuidString)")
            .appendingPathExtension("xlsx")
        defer {
            try? FileManager.default.removeItem(at: url)
        }

        let document = XLDocument()
        let sharedStringsPath = try OPCFilePath(string: "/xl/custom/sharedStrings.xml")
        let stylesPath = try OPCFilePath(string: "/xl/custom/styles.xml")
        document.package.sharedStrings.path = sharedStringsPath
        document.package.styles.path = stylesPath
        document.package.styles.file = try XLStylesFile(xmlDocument: XMLDocument(children: [
            XMLElement(
                name: XMLName(name: "styleSheet"),
                children: [
                    XMLElement(name: XMLName(name: "opaqueStyle")),
                ]
            ),
        ]))

        try document.save(to: url)

        let package = try OPCPackage(data: Data(contentsOf: url))
        let workbookRelsPath = try OPCFilePath(string: "/xl/_rels/workbook.xml.rels")
        let contentTypesPath = try OPCFilePath(string: "/[Content_Types].xml")
        let workbookRels = try #require(try package.fileWithPath(OPCRelsFile.self, at: workbookRelsPath, read: OPCRelsFile.init(xmlDocument:)))
        let contentTypes = try #require(try package.fileWithPath(OPCContentTypesFile.self, at: contentTypesPath, read: OPCContentTypesFile.init(xmlDocument:)))

        #expect(package.data(at: sharedStringsPath) != nil)
        #expect(package.data(at: stylesPath) != nil)
        #expect(package.data(at: try OPCFilePath(string: "/xl/sharedStrings.xml")) == nil)
        #expect(package.data(at: try OPCFilePath(string: "/xl/styles.xml")) == nil)
        #expect(workbookRels.file.relationships.contains {
            $0.type == XMLNamespaceURI.sharedStrings.string &&
            $0.target == "custom/sharedStrings.xml"
        })
        #expect(workbookRels.file.relationships.contains {
            $0.type == XMLNamespaceURI.styles.string &&
            $0.target == "custom/styles.xml"
        })
        #expect(contentTypes.file.overrides[sharedStringsPath] == OPCContentTypes.sharedStrings)
        #expect(contentTypes.file.overrides[stylesPath] == OPCContentTypes.styles)
    }

    @Test func preservesOpenedStylesXMLFromWorkbookRelationship() throws {
        var package = try OPCPackage(data: Data(
            contentsOf: try #require(Bundle.module.url(forResource: "simple", withExtension: "xlsx"))
        ))
        let stylesPath = try OPCFilePath(string: "/xl/styles/custom.xml")
        let workbookRelsPath = try OPCFilePath(string: "/xl/_rels/workbook.xml.rels")
        let stylesData = Data("""
            <styleSheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">
              <opaqueStyle/>
            </styleSheet>
            """.utf8)
        try package.insertFile(
            data: Data("""
                <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
                <Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
                  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet1.xml"/>
                  <Relationship Id="rId2" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/sharedStrings" Target="sharedStrings.xml"/>
                  <Relationship Id="rId3" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles/custom.xml"/>
                </Relationships>
                """.utf8),
            at: workbookRelsPath
        )
        try package.insertFile(data: stylesData, at: stylesPath)

        let destinationURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("swift-xlsx-tests-\(UUID().uuidString)")
            .appendingPathExtension("xlsx")
        defer {
            try? FileManager.default.removeItem(at: destinationURL)
        }

        let document = try XLDocument(opcPackage: package)
        try document.save(to: destinationURL)

        let savedPackage = try OPCPackage(data: Data(contentsOf: destinationURL))
        let savedWorkbookRels = try #require(try savedPackage.fileWithPath(OPCRelsFile.self, at: workbookRelsPath, read: OPCRelsFile.init(xmlDocument:)))
        let savedStylesXML = try String(decoding: #require(savedPackage.data(at: stylesPath)), as: UTF8.self)

        #expect(savedStylesXML.contains(#"<opaqueStyle/>"#))
        #expect(savedPackage.data(at: try OPCFilePath(string: "/xl/styles.xml")) == nil)
        #expect(savedWorkbookRels.file.relationships.contains {
            $0.type == XMLNamespaceURI.styles.string &&
            $0.target == "styles/custom.xml"
        })
    }

    @Test func opensOnlyWorksheetRelationshipTypesAsWorksheets() throws {
        let chartSheetRelationshipType = "http://schemas.openxmlformats.org/officeDocument/2006/relationships/chartsheet"
        let chartSheetData = Data("<chartsheet/>".utf8)
        var package = OPCPackage()
        try package.insertFile(
            data: Data("""
                <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
                <Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
                  <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
                  <Default Extension="xml" ContentType="application/xml"/>
                  <Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>
                  <Override PartName="/xl/worksheets/sheet1.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>
                  <Override PartName="/xl/chartsheets/sheet1.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>
                </Types>
                """.utf8),
            at: OPCFilePath(string: "/[Content_Types].xml")
        )
        try package.insertFile(
            data: Data("""
                <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
                <Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
                  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/>
                </Relationships>
                """.utf8),
            at: OPCFilePath(string: "/_rels/.rels")
        )
        try package.insertFile(
            data: Data("""
                <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
                <workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">
                  <sheets>
                    <sheet name="Sheet1" sheetId="1" r:id="rId1"/>
                    <sheet name="Chart1" sheetId="2" r:id="rId2"/>
                  </sheets>
                </workbook>
                """.utf8),
            at: OPCFilePath(string: "/xl/workbook.xml")
        )
        try package.insertFile(
            data: Data("""
                <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
                <Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
                  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet1.xml"/>
                  <Relationship Id="rId2" Type="\(chartSheetRelationshipType)" Target="chartsheets/sheet1.xml"/>
                </Relationships>
                """.utf8),
            at: OPCFilePath(string: "/xl/_rels/workbook.xml.rels")
        )
        try package.insertFile(
            data: Data("<worksheet/>".utf8),
            at: OPCFilePath(string: "/xl/worksheets/sheet1.xml")
        )
        try package.insertFile(
            data: chartSheetData,
            at: OPCFilePath(string: "/xl/chartsheets/sheet1.xml")
        )

        let destinationURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("swift-xlsx-tests-\(UUID().uuidString)")
            .appendingPathExtension("xlsx")
        defer {
            try? FileManager.default.removeItem(at: destinationURL)
        }

        let document = try XLDocument(opcPackage: package)
        #expect(document.package.workbook.file.sheets.map(\.sheetID) == [1, 2])
        #expect(document.package.workbook.file.worksheetByID.keys.sorted() == [1])
        #expect(document.workbook.worksheets.map(\.sheetID) == [1])

        try document.save(to: destinationURL)

        let savedPackage = try OPCPackage(data: Data(contentsOf: destinationURL))
        let savedWorkbookRelsPath = try OPCFilePath(string: "/xl/_rels/workbook.xml.rels")
        let savedWorkbookRelsFile = try savedPackage.fileWithPath(OPCRelsFile.self, at: savedWorkbookRelsPath, read: OPCRelsFile.init(xmlDocument:))
        let savedWorkbookRels = try #require(savedWorkbookRelsFile)
        let savedChartSheetRelationship = try #require(
            savedWorkbookRels.file.relationships.first { $0.id == "rId2" }
        )
        let chartSheetPath = try OPCFilePath(string: "/xl/chartsheets/sheet1.xml")
        let generatedSheetPath = try OPCFilePath(string: "/xl/worksheets/sheet2.xml")

        #expect(savedChartSheetRelationship.type == chartSheetRelationshipType)
        #expect(savedChartSheetRelationship.target == "chartsheets/sheet1.xml")
        #expect(savedPackage.data(at: chartSheetPath) == chartSheetData)
        #expect(savedPackage.data(at: generatedSheetPath) == nil)
    }

    @Test func worksheetNameUsesWorkbookSheetEntry() throws {
        let document = XLDocument()
        let worksheet = try #require(document.workbook.worksheets.first)

        #expect(worksheet.name == "Sheet1")

        worksheet.name = "Renamed"

        #expect(document.package.workbook.file.sheets[0].name == "Renamed")
    }

    @Test func worksheetExposesDataValidationThroughFile() throws {
        let document = XLDocument()
        let worksheet = try #require(document.workbook.worksheets.first)

        worksheet.dataValidation = XLDataValidations(
            validations: [
                XLDataValidation(
                    address: XLCellRangeAddressList([
                        XLCellRangeAddress("B2:B10")!,
                    ]),
                    validationType: .whole,
                    formula1: "1",
                    formula2: "10"
                ),
            ]
        )

        #expect(worksheet.file.dataValidations == worksheet.dataValidation)
        #expect(worksheet.file.dataValidations.validations.first?.address?.description == "B2:B10")
    }

    @Test func workbookWorksheetsShareWorksheetFileInstances() throws {
        let document = XLDocument()
        let worksheet = try #require(document.workbook.worksheets.first)
        let file = try #require(document.package.workbook.file.worksheetByID[1]?.file)

        #expect(worksheet.file === file)
    }

    @Test func worksheetExposesRowsThroughHandles() throws {
        let document = XLDocument()
        let worksheet = try #require(document.workbook.worksheets.first)

        #expect(worksheet.maxRowNumber == nil)
        #expect(worksheet.existingRow(3) == nil)
        #expect(worksheet.existingRowNumbers == [])

        let row = worksheet.row(3)
        row.storage.cell(column: 2).value = .string("value")

        #expect(row.number == 3)
        #expect(worksheet.maxRowNumber == 3)
        #expect(worksheet.existingRowNumbers == [3])
        #expect(worksheet.existingRows.map(\.number) == [3])
        #expect(worksheet.existingRows.map(\.existingColumnNumbers) == [[2]])
        #expect(worksheet.existingRow(3)?.storage.existingCell(column: 2)?.value == .string("value"))
    }

    @Test func worksheetExposesColumnsThroughHandles() throws {
        let document = XLDocument()
        let worksheet = try #require(document.workbook.worksheets.first)

        #expect(worksheet.maxColumnNumber == nil)
        #expect(worksheet.existingColumn(3) == nil)
        #expect(worksheet.existingColumnNumbers == [])

        let column = worksheet.column(3)
        column.width = 20
        column.format = XLCellFormat(numberFormat: .builtin(id: 14))
        column.hidden = true
        column.bestFit = true
        column.outlineLevel = 2
        column.collapsed = true
        column.phonetic = true
        worksheet.column(5).width = 8.5

        #expect(column.number == 3)
        #expect(worksheet.maxColumnNumber == 5)
        #expect(worksheet.existingColumnNumbers == [3, 5])
        #expect(worksheet.existingColumns.map(\.number) == [3, 5])
        #expect(worksheet.existingColumns.map(\.width) == [20, 8.5])
        #expect(worksheet.existingColumn(3)?.width == 20)
        #expect(worksheet.existingColumn(3)?.format == XLCellFormat(numberFormat: .builtin(id: 14)))
        #expect(worksheet.existingColumn(3)?.hidden == true)
        #expect(worksheet.existingColumn(3)?.bestFit == true)
        #expect(worksheet.existingColumn(3)?.outlineLevel == 2)
        #expect(worksheet.existingColumn(3)?.collapsed == true)
        #expect(worksheet.existingColumn(3)?.phonetic == true)
    }

    @Test func rowExposesCellsThroughHandles() throws {
        let document = XLDocument()
        let worksheet = try #require(document.workbook.worksheets.first)
        let row = worksheet.row(3)

        #expect(row.maxColumnNumber == nil)
        #expect(row.existingCell(column: 2) == nil)
        #expect(row.existingColumnNumbers == [])

        let cell = row.cell(column: 2)
        cell.value = .string("value")
        row.cell(column: 4).value = .string("right")

        #expect(cell.address == XLCellAddress(row: 3, column: 2))
        #expect(row.maxColumnNumber == 4)
        #expect(row.existingColumnNumbers == [2, 4])
        #expect(row.existingCells.map(\.column) == [2, 4])
        #expect(row.existingCells.map(\.value) == [.string("value"), .string("right")])
        #expect(row.existingCell(column: 2)?.value == .string("value"))
    }

    @Test func worksheetExposesCellsThroughHandles() throws {
        let document = XLDocument()
        let worksheet = try #require(document.workbook.worksheets.first)
        let address = try #require(XLCellAddress("D4"))

        #expect(worksheet.existingCell(row: 3, column: 2) == nil)
        #expect(worksheet.existingCell(address: address) == nil)

        worksheet.cell(row: 3, column: 2).value = .string("left")
        worksheet.cell(address: address).value = .string("right")

        #expect(worksheet.existingCell(row: 3, column: 2)?.address == XLCellAddress(row: 3, column: 2))
        #expect(worksheet.existingCell(row: 3, column: 2)?.value == .string("left"))
        #expect(worksheet.existingCell(address: address)?.address == address)
        #expect(worksheet.existingCell(address: address)?.value == .string("right"))
    }

    @Test func appendsWorksheet() throws {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("swift-xlsx-tests-\(UUID().uuidString)")
            .appendingPathExtension("xlsx")
        defer {
            try? FileManager.default.removeItem(at: url)
        }

        let document = XLDocument()
        let worksheet = try document.workbook.appendWorksheet(name: "Extra")

        #expect(worksheet.sheetID == 2)
        #expect(worksheet.name == "Extra")
        #expect(document.workbook.worksheets.map(\.sheetID) == [1, 2])
        #expect(document.package.workbookRels.file.relationships.map(\.id) == ["rId1", "rId2"])

        try document.save(to: url)

        let package = try OPCPackage(data: Data(contentsOf: url))
        let workbookXML = try String(
            decoding: #require(package.data(at: OPCFilePath(string: "/xl/workbook.xml"))),
            as: UTF8.self
        )
        let workbookRelsPath = try OPCFilePath(string: "/xl/_rels/workbook.xml.rels")
        let workbookRels = try #require(try package.fileWithPath(OPCRelsFile.self, at: workbookRelsPath, read: OPCRelsFile.init(xmlDocument:)))

        #expect(workbookXML.contains(#"<sheet name="Extra" sheetId="2" r:id="rId2"/>"#))
        #expect(workbookRels.file.relationships.contains {
            $0.id == "rId2" &&
            $0.type == XMLNamespaceURI.worksheet.string &&
            $0.target == "worksheets/sheet2.xml"
        })
        #expect(try package.data(at: OPCFilePath(string: "/xl/worksheets/sheet2.xml")) != nil)
    }

    @Test func removesWorksheet() throws {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("swift-xlsx-tests-\(UUID().uuidString)")
            .appendingPathExtension("xlsx")
        defer {
            try? FileManager.default.removeItem(at: url)
        }

        let document = XLDocument()
        let worksheet = try document.workbook.appendWorksheet(name: "Extra")
        document.workbook.removeWorksheet(sheetID: worksheet.sheetID)

        #expect(document.workbook.worksheets.map(\.sheetID) == [1])
        #expect(document.package.workbookRels.file.relationships.map(\.id) == ["rId1"])

        try document.save(to: url)

        let package = try OPCPackage(data: Data(contentsOf: url))
        let fixtureURL = try #require(Bundle.module.resourceURL?.appendingPathComponent("example-documents/default"))
        let fixturePackage = try OPCPackage(directoryURL: fixtureURL)
        let paths = package.allFilePaths()

        #expect(paths == fixturePackage.allFilePaths())
        for path in paths {
            let data = try #require(package.data(at: path))
            let fixtureData = try #require(fixturePackage.data(at: path))
            if isFormattedXMLFile(path) {
                #expect(try normalizedXMLString(data) == normalizedXMLString(fixtureData))
            } else {
                #expect(data == fixtureData)
            }
        }
    }

    @Test func preservesOpaqueFiles() throws {
        let sourceURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("swift-xlsx-tests-\(UUID().uuidString)")
            .appendingPathExtension("xlsx")
        let destinationURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("swift-xlsx-tests-\(UUID().uuidString)")
            .appendingPathExtension("xlsx")
        defer {
            try? FileManager.default.removeItem(at: sourceURL)
            try? FileManager.default.removeItem(at: destinationURL)
        }

        let sourceData = try Data(contentsOf: try #require(Bundle.module.url(forResource: "simple", withExtension: "xlsx")))
        var package = try OPCPackage(data: sourceData)
        try package.insertFile(data: Data([0xde, 0xad, 0xbe, 0xef]), at: OPCFilePath(string: "/custom/item.bin"))
        try package.insertFile(
            data: Data("""
                <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
                <Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
                  <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
                  <Default Extension="xml" ContentType="application/xml"/>
                  <Override PartName="/custom/item.bin" ContentType="application/octet-stream"/>
                  <Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>
                  <Override PartName="/xl/worksheets/sheet1.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>
                  <Override PartName="/xl/sharedStrings.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sharedStrings+xml"/>
                </Types>
                """.utf8),
            at: OPCFilePath(string: "/[Content_Types].xml")
        )
        try package.data().write(to: sourceURL)

        let document = try XLDocument.open(url: sourceURL)
        try document.save(to: destinationURL)

        let savedPackage = try OPCPackage(data: Data(contentsOf: destinationURL))
        let contentTypesXML = try String(
            decoding: #require(savedPackage.data(at: OPCFilePath(string: "/[Content_Types].xml"))),
            as: UTF8.self
        )

        #expect(try savedPackage.data(at: OPCFilePath(string: "/custom/item.bin")) == Data([0xde, 0xad, 0xbe, 0xef]))
        #expect(contentTypesXML.contains(#"PartName="/custom/item.bin""#))
        #expect(contentTypesXML.contains(#"ContentType="application/octet-stream""#))
    }

    @Test func preservesOpenedRelationshipTargets() throws {
        let sourceURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("swift-xlsx-tests-\(UUID().uuidString)")
            .appendingPathExtension("xlsx")
        let destinationURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("swift-xlsx-tests-\(UUID().uuidString)")
            .appendingPathExtension("xlsx")
        defer {
            try? FileManager.default.removeItem(at: sourceURL)
            try? FileManager.default.removeItem(at: destinationURL)
        }

        var package = try OPCPackage(data: Data(
            contentsOf: try #require(Bundle.module.url(forResource: "simple", withExtension: "xlsx"))
        ))
        let worksheetData = Data("""
            <worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">
              <sheetData>
                <row r="1"><c r="A1" t="s"><v>0</v></c></row>
              </sheetData>
              <opaque>worksheet</opaque>
            </worksheet>
            """.utf8)
        let sharedStringsData = Data("""
            <sst xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" count="1" uniqueCount="1">
              <si><r><rPr><b/></rPr><t>Rich</t></r><r><t> text</t></r></si>
            </sst>
            """.utf8)
        try package.insertFile(
            data: worksheetData,
            at: OPCFilePath(string: "/xl/worksheets/sheet1.xml")
        )
        try package.insertFile(
            data: sharedStringsData,
            at: OPCFilePath(string: "/xl/sharedStrings.xml")
        )
        try package.data().write(to: sourceURL)

        let document = try XLDocument.open(url: sourceURL)
        try document.save(to: destinationURL)

        let savedPackage = try OPCPackage(data: Data(contentsOf: destinationURL))

        let savedWorksheetXML = try String(
            decoding: #require(savedPackage.data(at: OPCFilePath(string: "/xl/worksheets/sheet1.xml"))),
            as: UTF8.self
        )
        #expect(savedWorksheetXML.contains(#"<opaque>worksheet</opaque>"#))
        #expect(savedWorksheetXML.contains(#"<c r="A1" t="s"><v>0</v></c>"#))

        let savedSharedStringsXML = try String(
            decoding: #require(savedPackage.data(at: OPCFilePath(string: "/xl/sharedStrings.xml"))),
            as: UTF8.self
        )
        #expect(savedSharedStringsXML.contains(#"<rPr><b/></rPr>"#))
        #expect(savedSharedStringsXML.contains(#"<t>Rich</t>"#))
        #expect(savedSharedStringsXML.contains(#"<t> text</t>"#))
    }
}

private func isFormattedXMLFile(_ path: OPCFilePath) -> Bool {
    guard let fileName = path.components.last?.lowercased() else {
        return false
    }
    return fileName.hasSuffix(".xml") || fileName.hasSuffix(".rels")
}

private func normalizedXMLString(_ data: Data) throws -> String {
    let document = try XMLDocument(data: data)
    removeFormattingText(in: document)
    return document.xmlString()
}

private func removeFormattingText(in node: XLSXXML.XMLNode) {
    for child in node.children {
        removeFormattingText(in: child)
    }

    let hasNonWhitespaceText = node.children.contains { child in
        guard let text = child as? XLSXXML.XMLText else {
            return false
        }
        return !text.value.allSatisfy(\.isWhitespace)
    }
    guard !hasNonWhitespaceText else {
        return
    }

    node.children = node.children.filter { child in
        guard let text = child as? XLSXXML.XMLText else {
            return true
        }
        return !text.value.allSatisfy(\.isWhitespace)
    }
}
