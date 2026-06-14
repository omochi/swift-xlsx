import Foundation
import Testing
import XLSX

@Suite
struct OPCPackageDirectoryTests {
    @Test func reads() throws {
        let fileManager = FileManager.default
        let sourceURL = try temporaryDirectoryURL(named: "source")
        defer {
            try? fileManager.removeItem(at: sourceURL)
        }

        try fileManager.createDirectory(
            at: sourceURL.appendingPathComponent("xl/worksheets", isDirectory: true),
            withIntermediateDirectories: true
        )
        try fileManager.createDirectory(
            at: sourceURL.appendingPathComponent("empty", isDirectory: true),
            withIntermediateDirectories: true
        )
        try Data("content types".utf8).write(to: sourceURL.appendingPathComponent("[Content_Types].xml"))
        try Data("sheet".utf8).write(to: sourceURL.appendingPathComponent("xl/worksheets/sheet1.xml"))

        let package = try OPCPackage(directoryURL: sourceURL)

        #expect(try package.childNames(in: OPCFilePath(string: "/")) == ["[Content_Types].xml", "empty", "xl"])
        #expect(try package.childNames(in: OPCFilePath(string: "/empty")) == [])
        #expect(try package.data(at: OPCFilePath(string: "/xl/worksheets/sheet1.xml")) == Data("sheet".utf8))
        #expect(directoryNames(in: package, at: "/xl") == ["worksheets"])
    }

    @Test func writes() throws {
        let fileManager = FileManager.default
        let destinationURL = try temporaryDirectoryURL(named: "destination")
        defer {
            try? fileManager.removeItem(at: destinationURL)
        }

        var package = OPCPackage()
        _ = try package.ensureDirectory(at: OPCFilePath(string: "/empty"))
        try package.insertFile(data: Data("content types".utf8), at: OPCFilePath(string: "/[Content_Types].xml"))
        try package.insertFile(data: Data("sheet".utf8), at: OPCFilePath(string: "/xl/worksheets/sheet1.xml"))

        try package.write(toDirectoryURL: destinationURL)

        var isDirectory: ObjCBool = false
        #expect(fileManager.fileExists(atPath: destinationURL.appendingPathComponent("empty").path, isDirectory: &isDirectory))
        #expect(isDirectory.boolValue)
        #expect(try Data(contentsOf: destinationURL.appendingPathComponent("[Content_Types].xml")) == Data("content types".utf8))
        #expect(try Data(contentsOf: destinationURL.appendingPathComponent("xl/worksheets/sheet1.xml")) == Data("sheet".utf8))

        let roundTripped = try OPCPackage(directoryURL: destinationURL)
        #expect(roundTripped.allFilePaths().map(\.description) == ["/[Content_Types].xml", "/xl/worksheets/sheet1.xml"])
    }

    @Test func buildsFromUnsortedFileEntries() throws {
        let package = try OPCPackage(fileEntries: [
            OPCFileEntry(
                path: OPCFilePath(string: "/xl/worksheets/sheet1.xml"),
                content: .file(Data("sheet".utf8))
            ),
            OPCFileEntry(
                path: OPCFilePath(string: "/xl"),
                content: .directory(["worksheets"])
            ),
            OPCFileEntry(
                path: OPCFilePath(string: "/[Content_Types].xml"),
                content: .file(Data("content types".utf8))
            ),
        ])

        #expect(try package.childNames(in: OPCFilePath(string: "/")) == ["[Content_Types].xml", "xl"])
        #expect(try package.childNames(in: OPCFilePath(string: "/xl")) == ["worksheets"])
        #expect(try package.data(at: OPCFilePath(string: "/xl/worksheets/sheet1.xml")) == Data("sheet".utf8))
    }
}

private func directoryNames(in package: OPCPackage, at path: String) -> [String]? {
    package.fileEntries().compactMap { entry -> [String]? in
        guard entry.path.description == path,
              case let .directory(names) = entry.content
        else {
            return nil
        }
        return names
    }.first
}

private func temporaryDirectoryURL(named name: String) throws -> URL {
    let url = FileManager.default.temporaryDirectory
        .appendingPathComponent("swift-xlsx-tests-\(UUID().uuidString)")
        .appendingPathComponent(name, isDirectory: true)
    try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    return url
}
