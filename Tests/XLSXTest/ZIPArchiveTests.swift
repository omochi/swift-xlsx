import Foundation
import Testing
import XLSX

@Suite
struct ZIPArchiveTests {
    @Test func decodesSimpleXLSX() throws {
        let url = try #require(Bundle.module.url(forResource: "simple", withExtension: "xlsx"))
        let data = try Data(contentsOf: url)

        let package = try OPCPackage(data: data)

        #expect(try package.childNames(in: OPCFilePath(string: "/")) == ["[Content_Types].xml", "_rels", "xl"])
        #expect(try package.childNames(in: OPCFilePath(string: "/xl")).contains("workbook.xml"))
        #expect(try package.childNames(in: OPCFilePath(string: "/xl/worksheets")) == ["sheet1.xml"])

        let workbookXML = try String(decoding: #require(package.data(at: OPCFilePath(string: "/xl/workbook.xml"))), as: UTF8.self)
        let worksheetXML = try String(decoding: #require(package.data(at: OPCFilePath(string: "/xl/worksheets/sheet1.xml"))), as: UTF8.self)
        let sharedStringsXML = try String(decoding: #require(package.data(at: OPCFilePath(string: "/xl/sharedStrings.xml"))), as: UTF8.self)

        #expect(workbookXML.contains("<workbook"))
        #expect(workbookXML.contains("Sheet1"))
        #expect(worksheetXML.contains("<sheetData>"))
        #expect(sharedStringsXML.contains("<sst"))
        #expect(package.allFilePaths().count == 6)
        #expect(package.allFilePaths().map(\.description).first == "/[Content_Types].xml")
    }

    @Test func encodesPackage() throws {
        var package = OPCPackage()
        _ = try package.ensureDirectory(at: OPCFilePath(string: "/empty"))
        try package.insertFile(data: Data("content types".utf8), at: OPCFilePath(string: "/[Content_Types].xml"))
        try package.insertFile(data: Data("sheet".utf8), at: OPCFilePath(string: "/xl/worksheets/sheet1.xml"))

        let archiveData = try package.data()
        let decoded = try OPCPackage(data: archiveData)

        #expect(try decoded.childNames(in: OPCFilePath(string: "/")) == ["[Content_Types].xml", "empty", "xl"])
        #expect(try decoded.childNames(in: OPCFilePath(string: "/empty")) == [])
        #expect(try decoded.data(at: OPCFilePath(string: "/xl/worksheets/sheet1.xml")) == Data("sheet".utf8))
    }

    @Test func encodesFileEntriesWithDeflateCompression() throws {
        var package = OPCPackage()
        let text = String(repeating: "<c><v>1234567890</v></c>", count: 200)
        try package.insertFile(data: Data(text.utf8), at: OPCFilePath(string: "/xl/worksheets/sheet1.xml"))

        let archiveData = try package.data()
        let records = try centralDirectoryRecords(in: archiveData)
        let record = try #require(records["xl/worksheets/sheet1.xml"])

        #expect(record.compressionMethod == 8)
        #expect(record.compressedSize < record.uncompressedSize)
        #expect(try OPCPackage(data: archiveData).data(at: OPCFilePath(string: "/xl/worksheets/sheet1.xml")) == Data(text.utf8))
    }
}

private struct TestZIPCentralDirectoryRecord {
    var compressionMethod: UInt16
    var compressedSize: UInt32
    var uncompressedSize: UInt32
}

private enum TestZIPError: Error {
    case invalidArchive
}

private func centralDirectoryRecords(in data: Data) throws -> [String: TestZIPCentralDirectoryRecord] {
    let eocdOffset = try endOfCentralDirectoryOffset(in: data)
    let entryCount = Int(try data.uint16(at: eocdOffset + 10))
    var offset = Int(try data.uint32(at: eocdOffset + 16))
    var records: [String: TestZIPCentralDirectoryRecord] = [:]

    for _ in 0..<entryCount {
        #expect(try data.uint32(at: offset) == 0x0201_4b50)

        let compressionMethod = try data.uint16(at: offset + 10)
        let compressedSize = try data.uint32(at: offset + 20)
        let uncompressedSize = try data.uint32(at: offset + 24)
        let fileNameLength = Int(try data.uint16(at: offset + 28))
        let extraFieldLength = Int(try data.uint16(at: offset + 30))
        let commentLength = Int(try data.uint16(at: offset + 32))
        let fileNameStart = offset + 46
        let fileNameEnd = fileNameStart + fileNameLength
        let fileName = String(decoding: data[fileNameStart..<fileNameEnd], as: UTF8.self)

        records[fileName] = TestZIPCentralDirectoryRecord(
            compressionMethod: compressionMethod,
            compressedSize: compressedSize,
            uncompressedSize: uncompressedSize
        )
        offset = fileNameEnd + extraFieldLength + commentLength
    }

    return records
}

private func endOfCentralDirectoryOffset(in data: Data) throws -> Int {
    let minimumEOCDSize = 22
    var offset = data.count - minimumEOCDSize

    while offset >= 0 {
        if try data.uint32(at: offset) == 0x0605_4b50 {
            return offset
        }
        offset -= 1
    }

    throw TestZIPError.invalidArchive
}

private extension Data {
    func uint16(at offset: Int) throws -> UInt16 {
        guard offset >= 0, offset + 2 <= count else {
            throw TestZIPError.invalidArchive
        }
        return UInt16(self[offset])
            | (UInt16(self[offset + 1]) << 8)
    }

    func uint32(at offset: Int) throws -> UInt32 {
        guard offset >= 0, offset + 4 <= count else {
            throw TestZIPError.invalidArchive
        }
        return UInt32(self[offset])
            | (UInt32(self[offset + 1]) << 8)
            | (UInt32(self[offset + 2]) << 16)
            | (UInt32(self[offset + 3]) << 24)
    }
}
