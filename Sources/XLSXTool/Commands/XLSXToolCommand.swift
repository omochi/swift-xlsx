import ArgumentParser

@main
public struct XLSXToolCommand: ParsableCommand {
    public static let configuration = CommandConfiguration(
        commandName: "xlsx-tool",
        abstract: "Utilities for unpacking and packing XLSX OPC packages.",
        subcommands: [
            ExtractCommand.self,
            PackCommand.self,
            ExampleDocumentsCommand.self,
        ]
    )

    public init() {}
}
