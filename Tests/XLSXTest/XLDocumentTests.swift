import Foundation
import Testing
import XLSX

@Suite
struct XLDocumentTests {
    @Test func savesDefaultDocumentFixture() throws {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("swift-xlsx-tests-\(UUID().uuidString)")
            .appendingPathExtension("xlsx")
        defer {
            try? FileManager.default.removeItem(at: url)
        }

        let document = XLDocument()
        try document.save(to: url)

        let data = try Data(contentsOf: url)
        let package = try OPCPackage(data: data)
        let fixtureURL = try #require(Bundle.module.resourceURL?.appendingPathComponent("default-document"))
        let fixturePackage = try OPCPackage(directoryURL: fixtureURL)

        let paths = package.allFilePaths()
        let fixturePaths = fixturePackage.allFilePaths()
        #expect(paths == fixturePaths)

        for path in paths {
            #expect(package.data(at: path) == fixturePackage.data(at: path))
        }
    }

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

        let document = try XLDocument.open(sourceURL)
        try document.save(to: destinationURL)

        let package = try OPCPackage(data: Data(contentsOf: destinationURL))
        let worksheetXML = try String(decoding: #require(package.data(at: OPCFilePath(string: "/xl/worksheets/sheet1.xml"))), as: UTF8.self)
        let sharedStringsXML = try String(decoding: #require(package.data(at: OPCFilePath(string: "/xl/sharedStrings.xml"))), as: UTF8.self)

        #expect(worksheetXML.contains("<c r=\"A1\" t=\"s\">"))
        #expect(worksheetXML.contains("<v>0</v>"))
        #expect(sharedStringsXML.contains("<t>A</t>"))
    }

    @Test func opensPlainSharedStringCellsAsStringValues() throws {
        let document = try XLDocument.open(try #require(Bundle.module.url(forResource: "simple", withExtension: "xlsx")))
        let worksheet = try #require(document.workbook.worksheets.first)

        #expect(worksheet.existingCell(row: 1, column: 1)?.value == .string("A"))
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

        let document = try XLDocument.open(sourceURL)
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
        let document = try XLDocument.open(try #require(Bundle.module.url(forResource: "simple", withExtension: "xlsx")))

        let worksheet = try #require(document.package.workbook.file.worksheetFromID[1])
        #expect(worksheet.path.description == "/xl/worksheets/sheet1.xml")
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
        #expect(document.package.workbook.file.worksheetFromID.keys.sorted() == [1])
        #expect(document.workbook.worksheets.map(\.sheetID) == [1])

        try document.save(to: destinationURL)

        let savedPackage = try OPCPackage(data: Data(contentsOf: destinationURL))
        let savedWorkbookRelsPath = try OPCFilePath(string: "/xl/_rels/workbook.xml.rels")
        let savedWorkbookRelsFile = try savedPackage.fileWithPath(OPCRelsFile.self, at: savedWorkbookRelsPath)
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

    @Test func workbookWorksheetsShareWorksheetFileInstances() throws {
        let document = XLDocument()
        let worksheet = try #require(document.workbook.worksheets.first)
        let file = try #require(document.package.workbook.file.worksheetFromID[1]?.file)

        #expect(worksheet.file === file)
    }

    @Test func worksheetExposesRowsThroughHandles() throws {
        let document = XLDocument()
        let worksheet = try #require(document.workbook.worksheets.first)

        #expect(worksheet.maxRowNumber == nil)
        #expect(worksheet.existingRow(3) == nil)
        #expect(worksheet.existingRowNumbers == [])

        let row = worksheet.row(3)
        row.storage.cell(column: 2).value = XLCellValue(rawValue: "value")

        #expect(row.number == 3)
        #expect(worksheet.maxRowNumber == 3)
        #expect(worksheet.existingRowNumbers == [3])
        #expect(worksheet.existingRow(3)?.storage.existingCell(column: 2)?.value == XLCellValue(rawValue: "value"))
    }

    @Test func rowExposesCellsThroughHandles() throws {
        let document = XLDocument()
        let worksheet = try #require(document.workbook.worksheets.first)
        let row = worksheet.row(3)

        #expect(row.maxColumnNumber == nil)
        #expect(row.existingCell(column: 2) == nil)
        #expect(row.existingColumnNumbers == [])

        let cell = row.cell(column: 2)
        cell.value = XLCellValue(rawValue: "value")

        #expect(cell.reference == XLCellReference(row: 3, column: 2))
        #expect(row.maxColumnNumber == 2)
        #expect(row.existingColumnNumbers == [2])
        #expect(row.existingCell(column: 2)?.value == XLCellValue(rawValue: "value"))
    }

    @Test func worksheetExposesCellsThroughHandles() throws {
        let document = XLDocument()
        let worksheet = try #require(document.workbook.worksheets.first)
        let reference = try #require(XLCellReference("D4"))

        #expect(worksheet.existingCell(row: 3, column: 2) == nil)
        #expect(worksheet.existingCell(reference: reference) == nil)

        worksheet.cell(row: 3, column: 2).value = XLCellValue(rawValue: "left")
        worksheet.cell(reference: reference).value = XLCellValue(rawValue: "right")

        #expect(worksheet.existingCell(row: 3, column: 2)?.reference == XLCellReference(row: 3, column: 2))
        #expect(worksheet.existingCell(row: 3, column: 2)?.value == XLCellValue(rawValue: "left"))
        #expect(worksheet.existingCell(reference: reference)?.reference == reference)
        #expect(worksheet.existingCell(reference: reference)?.value == XLCellValue(rawValue: "right"))
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
        let workbookRels = try #require(try package.fileWithPath(OPCRelsFile.self, at: workbookRelsPath))

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
        let fixtureURL = try #require(Bundle.module.resourceURL?.appendingPathComponent("default-document"))
        let fixturePackage = try OPCPackage(directoryURL: fixtureURL)
        let paths = package.allFilePaths()

        #expect(paths == fixturePackage.allFilePaths())
        for path in paths {
            #expect(package.data(at: path) == fixturePackage.data(at: path))
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

        let document = try XLDocument.open(sourceURL)
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

        let document = try XLDocument.open(sourceURL)
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
