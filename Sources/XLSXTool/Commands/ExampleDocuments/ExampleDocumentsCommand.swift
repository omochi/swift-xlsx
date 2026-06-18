import ArgumentParser
import Foundation
import XLSX

public struct ExampleDocumentsCommand: ParsableCommand {
    public static let configuration = CommandConfiguration(
        commandName: "example-documents",
        abstract: "Create example XLSX documents."
    )

    @Argument(help: "The destination directory.")
    public var output: String?

    public init() {}

    public func run() throws {
        let outputPath = output ?? FileManager.default.currentDirectoryPath
        let outputURL = URL(fileURLWithPath: outputPath)
        try FileManager.default.createDirectory(at: outputURL, withIntermediateDirectories: true)
        try XLExampleDocuments.defaultDocument().save(to: outputURL.appendingPathComponent("default.xlsx"))
        try XLExampleDocuments.simpleDocument().save(to: outputURL.appendingPathComponent("simple.xlsx"))
        try XLExampleDocuments.dataValidationDocument().save(to: outputURL.appendingPathComponent("data-validation.xlsx"))
        try XLExampleDocuments.columnDocument().save(to: outputURL.appendingPathComponent("column.xlsx"))
        try XLExampleDocuments.formulaDocument().save(to: outputURL.appendingPathComponent("formula.xlsx"))
        try XLExampleDocuments.worksheetsDocument().save(to: outputURL.appendingPathComponent("worksheets.xlsx"))
        try XLExampleDocuments.styleDocument().save(to: outputURL.appendingPathComponent("style.xlsx"))
    }
}
