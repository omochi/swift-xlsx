import ArgumentParser

public struct TestHelperCommand: ParsableCommand {
    public static let configuration = CommandConfiguration(
        commandName: "test-helper",
        abstract: "Commands for generating test fixtures.",
        shouldDisplay: false,
        subcommands: [
            CreateDefaultDocumentCommand.self,
        ]
    )

    public init() {}
}
