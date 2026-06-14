import ArgumentParser
import Foundation
import XLSX

public struct ExtractCommand: ParsableCommand {
    public static let configuration = CommandConfiguration(
        commandName: "extract",
        abstract: "Extract an XLSX file into a directory."
    )

    @Argument(help: "The XLSX file to extract.")
    public var input: String

    @Option(name: [.short, .long], help: "The destination directory.")
    public var output: String?

    public init() {}

    public func run() throws {
        let inputURL = URL(fileURLWithPath: input)
        let outputURL = output.map(URL.init(fileURLWithPath:)) ?? XLSXToolsOutputURL.extractDefault(for: inputURL)
        let data = try Data(contentsOf: inputURL)
        let package = try OPCPackage(data: data)
        try package.write(toDirectoryURL: outputURL)
    }
}
