import ArgumentParser
import Foundation
import XLSX

extension ExampleDocumentsCommand {
    public struct DefaultCommand: ParsableCommand {
        public static let configuration = CommandConfiguration(
            commandName: "default",
            abstract: "Create the default empty XLDocument XLSX file."
        )

        @Argument(help: "The destination XLSX file.")
        public var output: String

        public init() {}

        public func run() throws {
            let outputURL = URL(fileURLWithPath: output)
            let document = XLDocument()
            try document.save(to: outputURL)
        }
    }
}
