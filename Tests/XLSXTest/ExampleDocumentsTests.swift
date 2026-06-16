import Foundation
import Testing
import XLSX
import XLSXTools

@Suite
struct ExampleDocumentsTests {
    @Test func savesDefaultDocumentFixture() throws {
        try expectGeneratedDocument(
            ExampleDocumentsCommand.makeDefaultDocument(),
            matchesFixtureNamed: "default"
        )
    }

    @Test func savesSimpleDocumentFixture() throws {
        try expectGeneratedDocument(
            try ExampleDocumentsCommand.makeSimpleDocument(),
            matchesFixtureNamed: "simple"
        )
    }

    @Test func savesFontsDocumentFixture() throws {
        try expectGeneratedDocument(
            try ExampleDocumentsCommand.makeFontsDocument(),
            matchesFixtureNamed: "fonts"
        )
    }

    private func expectGeneratedDocument(
        _ document: XLDocument,
        matchesFixtureNamed fixtureName: String
    ) throws {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("swift-xlsx-tests-\(UUID().uuidString)")
            .appendingPathExtension("xlsx")
        defer {
            try? FileManager.default.removeItem(at: url)
        }

        try document.save(to: url)

        let package = try OPCPackage(data: Data(contentsOf: url))
        let fixtureURL = try #require(Bundle.module.resourceURL?.appendingPathComponent("example-documents/\(fixtureName)"))
        let fixturePackage = try OPCPackage(directoryURL: fixtureURL)

        let paths = package.allFilePaths()
        let fixturePaths = fixturePackage.allFilePaths()
        #expect(paths == fixturePaths)

        for path in paths {
            #expect(package.data(at: path) == fixturePackage.data(at: path))
        }
    }
}
