import ArgumentParser
import Foundation
import XLSX

public struct ExampleDocumentsCommand: ParsableCommand {
    public static let configuration = CommandConfiguration(
        commandName: "example-documents",
        abstract: "Create example XLSX documents."
    )

    @Argument(help: "The destination directory.")
    public var output: String

    public init() {}

    public func run() throws {
        let outputURL = URL(fileURLWithPath: output)
        try FileManager.default.createDirectory(at: outputURL, withIntermediateDirectories: true)
        try Self.makeDefaultDocument().save(to: outputURL.appendingPathComponent("default.xlsx"))
        try Self.makeSimpleDocument().save(to: outputURL.appendingPathComponent("simple.xlsx"))
        try Self.makeFontsDocument().save(to: outputURL.appendingPathComponent("fonts.xlsx"))
    }

    public static func makeDefaultDocument() -> XLDocument {
        XLDocument()
    }

    public static func makeSimpleDocument() throws -> XLDocument {
        let document = XLDocument()
        let worksheet = try document.workbook.worksheets.first ?? document.workbook.appendWorksheet(name: "Sheet1")
        worksheet.cell(row: 1, column: 1).value = .string("A")
        worksheet.cell(row: 1, column: 2).value = .string("B")
        worksheet.cell(row: 1, column: 3).value = .string("C")
        return document
    }

    public static func makeFontsDocument() throws -> XLDocument {
        let document = XLDocument()
        let worksheet = try document.workbook.worksheets.first ?? document.workbook.appendWorksheet(name: "Sheet1")
        writeFontExamples(to: worksheet)
        return document
    }

    static func writeFontExamples(to worksheet: XLWorksheet) {
        let examples: [(String, XLFont)] = [
            ("bold", XLFont(bold: true)),
            ("italic", XLFont(italic: true)),
            ("strike", XLFont(strike: true)),
            ("condense", XLFont(condense: true)),
            ("extend", XLFont(extend: true)),
            ("outline", XLFont(outline: true)),
            ("shadow", XLFont(shadow: true)),
            ("size", XLFont(size: 18)),
            ("name", XLFont(name: "Courier New")),
        ]

        for (index, example) in examples.enumerated() {
            let cell = worksheet.cell(row: index + 1, column: 1)
            cell.value = .string(example.0)
            cell.format = XLCellFormat(font: example.1)
        }
    }
}
