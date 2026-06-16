import ArgumentParser

public struct ExampleDocumentsCommand: ParsableCommand {
    public static let configuration = CommandConfiguration(
        commandName: "example-documents",
        abstract: "Create example XLSX documents.",
        subcommands: [
            ExampleDocumentsCommand.DefaultCommand.self,
            ExampleDocumentsCommand.SimpleCommand.self,
        ]
    )

    public init() {}
}
