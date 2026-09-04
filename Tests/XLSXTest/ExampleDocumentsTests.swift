import class Foundation.Bundle
import struct Foundation.Data
import class Foundation.FileManager
import struct Foundation.UUID
import Testing
import XLSX
import XLSXExamples
import XLSXXML

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

    @Test func savesExampleDocumentFixture() throws {
        try expectGeneratedDocument(
            try XLExampleDocuments.exampleDocument(),
            matchesFixtureNamed: "example"
        )
    }

    @Test func exampleDocumentCoversVisibleSupportedFeatures() throws {
        let document = try XLExampleDocuments.exampleDocument()

        #expect(document.workbook.worksheets.map(\.name) == [
            "formula",
            "column",
            "number format",
            "font",
            "fill",
            "border",
            "data validation",
            "password",
            "hidden",
            "cell value",
            "freeze panes",
            "cell style",
            "very hidden",
        ])

        let formulaWorksheet = try worksheet(named: "formula", in: document)
        #expect(formulaWorksheet.existingCell(row: 4, column: 2)?.formula?.kind == .regular)
        #expect(formulaWorksheet.existingCell(row: 1, column: 4)?.formula?.kind == .sharedDefinition)
        #expect(formulaWorksheet.existingCell(row: 2, column: 4)?.formula?.kind == .sharedReference)
        #expect(formulaWorksheet.existingCell(row: 6, column: 2)?.value == .text("10"))

        let columnWorksheet = try worksheet(named: "column", in: document)
        #expect(columnWorksheet.existingColumn(4)?.format?.numberFormat == .percent)
        #expect(columnWorksheet.existingCell(row: 1, column: 4)?.format?.numberFormat == .percent)
        #expect(columnWorksheet.existingColumn(5)?.hidden == true)
        #expect(columnWorksheet.existingColumn(7)?.bestFit == true)
        #expect(columnWorksheet.existingColumn(8)?.outlineLevel == 1)
        #expect(columnWorksheet.existingColumn(9)?.collapsed == true)

        let fontWorksheet = try worksheet(named: "font", in: document)
        #expect(fontWorksheet.existingRowNumbers.count == 14)
        #expect(fontWorksheet.existingCell(row: 4, column: 1)?.format?.font?.condense == true)
        #expect(fontWorksheet.existingCell(row: 5, column: 1)?.format?.font?.extend == true)
        #expect(fontWorksheet.existingCell(row: 6, column: 1)?.format?.font?.outline == true)
        #expect(fontWorksheet.existingCell(row: 7, column: 1)?.format?.font?.shadow == true)

        let fillWorksheet = try worksheet(named: "fill", in: document)
        #expect(fillWorksheet.existingRowNumbers.count == 19)
        #expect(fillWorksheet.existingRows.allSatisfy { row in
            row.existingCell(column: 2)?.format?.fill != nil
        })

        let borderWorksheet = try worksheet(named: "border", in: document)
        #expect((1...14).compactMap { row in
            borderWorksheet.existingCell(row: row, column: 5)?.format?.border?.bottom?.style
        } == [
            .none,
            .thin,
            .medium,
            .dashed,
            .dotted,
            .thick,
            .double,
            .hair,
            .mediumDashed,
            .dashDot,
            .mediumDashDot,
            .dashDotDot,
            .mediumDashDotDot,
            .slantDashDot,
        ])

        let validationWorksheet = try worksheet(named: "data validation", in: document)
        let validations = try #require(validationWorksheet.dataValidation?.validations)
        #expect(validations.map(\.validationType) == [
            .list,
            .whole,
            .decimal,
            .date,
            .time,
            .textLength,
            .custom,
        ])
        #expect(validations.first?.address?.ranges.count == 2)

        let passwordWorksheet = try worksheet(named: "password", in: document)
        #expect(passwordWorksheet.sheetProtection?.passwordHashInfo.algorithmName == "SHA-512")
        #expect(passwordWorksheet.existingCell(row: 4, column: 2)?.format?.protection?.locked == false)
        #expect(passwordWorksheet.existingCell(row: 5, column: 2)?.format?.protection?.hidden == true)

        #expect(try worksheet(named: "hidden", in: document).state == .hidden)
        #expect(try worksheet(named: "very hidden", in: document).state == .veryHidden)

        let cellValueWorksheet = try worksheet(named: "cell value", in: document)
        let richText = try #require(cellValueWorksheet.existingCell(row: 2, column: 2)?.value.text)
        guard case .rich(let richTextRuns) = richText.content else {
            Issue.record("Expected rich text content.")
            return
        }
        #expect(richTextRuns.count == 3)

        let phoneticText = try #require(cellValueWorksheet.existingCell(row: 3, column: 2)?.value.text)
        #expect(phoneticText.phoneticRuns == [
            XLPhoneticRun(text: "かんじ", startIndex: 0, endIndex: 2),
        ])
        #expect(phoneticText.phoneticProperties == XLPhoneticProperties(
            fontID: 0,
            type: "Hiragana",
            alignment: "center"
        ))
        #expect(cellValueWorksheet.existingCell(row: 5, column: 2)?.value == .boolean(true))
        #expect(cellValueWorksheet.existingCell(row: 6, column: 2)?.value == .boolean(false))
        #expect(cellValueWorksheet.existingCell(row: 8, column: 2)?.value == .error("#N/A"))
        #expect(cellValueWorksheet.existingColumn(2)?.phonetic == true)

        let freezePanesWorksheet = try worksheet(named: "freeze panes", in: document)
        #expect(freezePanesWorksheet.frozenPanes == XLFrozenPanes(rowCount: 1, columnCount: 1))
        #expect(freezePanesWorksheet.maxRowNumber == 50)
        #expect(freezePanesWorksheet.maxColumnNumber == 10)

        let cellStyleWorksheet = try worksheet(named: "cell style", in: document)
        let namedStyle = try #require(document.package.styles.file.cellStyles.first {
            $0.name == "Example Percent"
        })
        let namedStyleCellFormat = try #require(cellStyleWorksheet.existingCell(row: 1, column: 2)?.format)
        #expect(namedStyleCellFormat.styleFormat == namedStyle.format)
        #expect(namedStyleCellFormat.numberFormat == namedStyle.format?.numberFormat)
        #expect(namedStyleCellFormat.font == namedStyle.format?.font)
        #expect(namedStyleCellFormat.fill == namedStyle.format?.fill)
        #expect(namedStyleCellFormat.border == namedStyle.format?.border)
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

    private func worksheet(named name: String, in document: XLDocument) throws -> XLWorksheet {
        try #require(document.workbook.worksheets.first { $0.name == name })
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
}
