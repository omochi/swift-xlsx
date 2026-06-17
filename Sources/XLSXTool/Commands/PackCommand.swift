import ArgumentParser
import Foundation
import XLSX

public struct PackCommand: ParsableCommand {
    public static let configuration = CommandConfiguration(
        commandName: "pack",
        abstract: "Pack a directory into an XLSX file."
    )

    @Argument(help: "The directory to package.")
    public var input: String

    @Option(name: [.short, .long], help: "The destination XLSX file.")
    public var output: String?

    public init() {}

    public func run() throws {
        let inputURL = URL(fileURLWithPath: input)
        let outputURL = output.map(URL.init(fileURLWithPath:)) ?? XLSXToolOutputURL.packDefault(for: inputURL)
        let package = try OPCPackage(directoryURL: inputURL)
        let data = try package.data()
        try data.write(to: outputURL, options: .atomic)
    }
}
