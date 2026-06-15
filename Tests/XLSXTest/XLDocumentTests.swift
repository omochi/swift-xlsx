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

    @Test func opensWorksheetsIntoWorkbookScope() throws {
        let document = try XLDocument.open(try #require(Bundle.module.url(forResource: "simple", withExtension: "xlsx")))

        let worksheet = try #require(document.workbook.worksheets[1])
        #expect(worksheet.path.description == "/xl/worksheets/sheet1.xml")
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
        let worksheetData = Data("<worksheet>opaque worksheet</worksheet>".utf8)
        let sharedStringsData = Data("<sst>opaque shared strings</sst>".utf8)
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
        #expect(savedWorksheetXML.contains("opaque worksheet"))
        #expect(try savedPackage.data(at: OPCFilePath(string: "/xl/sharedStrings.xml")) == sharedStringsData)
    }
}
