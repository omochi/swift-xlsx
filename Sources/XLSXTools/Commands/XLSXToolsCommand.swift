import ArgumentParser

@main
public struct XLSXToolsCommand: ParsableCommand {
    public static let configuration = CommandConfiguration(
        commandName: "xlsx-tools",
        abstract: "Utilities for unpacking and packing XLSX OPC packages.",
        subcommands: [
            ExtractCommand.self,
            PackCommand.self,
            TestHelperCommand.self,
        ]
    )

    public init() {}
}
