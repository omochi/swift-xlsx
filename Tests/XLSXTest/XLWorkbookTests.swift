import Foundation
import Testing
import XLSX

@Suite
struct XLWorkbookTests {
    @Test func savesHelloWorldWorkbook() throws {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("swift-xlsx-tests-\(UUID().uuidString)")
            .appendingPathExtension("xlsx")
        defer {
            try? FileManager.default.removeItem(at: url)
        }

        let workbook = XLWorkbook()
        try workbook.save(to: url)

        let data = try Data(contentsOf: url)
        let package = try OPCPackage(data: data)

        #expect(package.allFilePaths().map(\.description) == [
            "/[Content_Types].xml",
            "/_rels/.rels",
            "/xl/_rels/workbook.xml.rels",
            "/xl/sharedStrings.xml",
            "/xl/workbook.xml",
            "/xl/worksheets/sheet1.xml",
        ])

        let workbookXML = try String(decoding: package.data(at: OPCFilePath(string: "/xl/workbook.xml")), as: UTF8.self)
        let worksheetXML = try String(decoding: package.data(at: OPCFilePath(string: "/xl/worksheets/sheet1.xml")), as: UTF8.self)
        let sharedStringsXML = try String(decoding: package.data(at: OPCFilePath(string: "/xl/sharedStrings.xml")), as: UTF8.self)

        #expect(workbookXML.contains("<sheet name=\"Sheet1\" sheetId=\"1\" r:id=\"rId1\"/>"))
        #expect(worksheetXML.contains("<c r=\"A1\" t=\"s\">"))
        #expect(sharedStringsXML.contains("count=\"1\""))
        #expect(sharedStringsXML.contains("uniqueCount=\"1\""))
        #expect(sharedStringsXML.contains("<t>hello world</t>"))
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

        let workbook = try XLWorkbook.open(sourceURL)
        try workbook.save(to: destinationURL)

        let package = try OPCPackage(data: Data(contentsOf: destinationURL))
        let worksheetXML = try String(decoding: package.data(at: OPCFilePath(string: "/xl/worksheets/sheet1.xml")), as: UTF8.self)
        let sharedStringsXML = try String(decoding: package.data(at: OPCFilePath(string: "/xl/sharedStrings.xml")), as: UTF8.self)

        #expect(worksheetXML.contains("<c r=\"A1\" t=\"s\">"))
        #expect(worksheetXML.contains("<v>0</v>"))
        #expect(sharedStringsXML.contains("<t>hello world</t>"))
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

        let workbook = try XLWorkbook.open(sourceURL)
        try workbook.save(to: destinationURL)

        let savedPackage = try OPCPackage(data: Data(contentsOf: destinationURL))
        let contentTypesXML = try String(
            decoding: savedPackage.data(at: OPCFilePath(string: "/[Content_Types].xml")),
            as: UTF8.self
        )

        #expect(try savedPackage.data(at: OPCFilePath(string: "/custom/item.bin")) == Data([0xde, 0xad, 0xbe, 0xef]))
        #expect(contentTypesXML.contains(#"PartName="/custom/item.bin""#))
        #expect(contentTypesXML.contains(#"ContentType="application/octet-stream""#))
    }
}
