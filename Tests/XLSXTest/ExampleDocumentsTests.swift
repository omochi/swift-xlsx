import Foundation
import Testing
import XLSX

@Suite
struct ExampleDocumentsTests {
    @Test func savesDefaultDocumentFixture() throws {
        try expectGeneratedDocument(
            XLExampleDocuments.defaultDocument(),
            matchesFixtureNamed: "default"
        )
    }

    @Test func savesSimpleDocumentFixture() throws {
        try expectGeneratedDocument(
            try XLExampleDocuments.simpleDocument(),
            matchesFixtureNamed: "simple"
        )
    }

    @Test func savesDataValidationDocumentFixture() throws {
        try expectGeneratedDocument(
            try XLExampleDocuments.dataValidationDocument(),
            matchesFixtureNamed: "data-validation"
        )
    }

    @Test func savesColumnDocumentFixture() throws {
        try expectGeneratedDocument(
            try XLExampleDocuments.columnDocument(),
            matchesFixtureNamed: "column"
        )
    }

    @Test func savesFormulaDocumentFixture() throws {
        try expectGeneratedDocument(
            try XLExampleDocuments.formulaDocument(),
            matchesFixtureNamed: "formula"
        )
    }

    @Test func savesWorksheetsDocumentFixture() throws {
        try expectGeneratedDocument(
            try XLExampleDocuments.worksheetsDocument(),
            matchesFixtureNamed: "worksheets"
        )
    }

    @Test func savesStyleDocumentFixture() throws {
        try expectGeneratedDocument(
            try XLExampleDocuments.styleDocument(),
            matchesFixtureNamed: "style"
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
            let data = try #require(package.data(at: path))
            let fixtureData = try #require(fixturePackage.data(at: path))
            if isFormattedXMLFile(path) {
                #expect(try normalizedXMLString(data) == normalizedXMLString(fixtureData))
            } else {
                #expect(data == fixtureData)
            }
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

    private func removeFormattingText(in node: XLSX.XMLNode) {
        for child in node.children {
            removeFormattingText(in: child)
        }

        let hasNonWhitespaceText = node.children.contains { child in
            guard let text = child as? XLSX.XMLText else {
                return false
            }
            return !text.value.allSatisfy(\.isWhitespace)
        }
        guard !hasNonWhitespaceText else {
            return
        }

        node.children = node.children.filter { child in
            guard let text = child as? XLSX.XMLText else {
                return true
            }
            return !text.value.allSatisfy(\.isWhitespace)
        }
    }
}
