import ArgumentParser
import Foundation
import XLSX

public struct CreateDefaultDocumentCommand: ParsableCommand {
    public static let configuration = CommandConfiguration(
        commandName: "create-default-document",
        abstract: "Create the default XLDocument XLSX file."
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
