import ArgumentParser
import Foundation
import XLSX

extension ExampleDocumentsCommand {
    public struct SimpleCommand: ParsableCommand {
        public static let configuration = CommandConfiguration(
            commandName: "simple",
            abstract: "Create an XLSX file with A, B, and C in the first row."
        )

        @Argument(help: "The destination XLSX file.")
        public var output: String

        public init() {}

        public func run() throws {
            let outputURL = URL(fileURLWithPath: output)
            let document = XLDocument()
            let worksheet = try document.workbook.worksheets.first ?? document.workbook.appendWorksheet(name: "Sheet1")
            worksheet.cell(row: 1, column: 1).value = .string("A")
            worksheet.cell(row: 1, column: 2).value = .string("B")
            worksheet.cell(row: 1, column: 3).value = .string("C")
            try document.save(to: outputURL)
        }
    }
}
