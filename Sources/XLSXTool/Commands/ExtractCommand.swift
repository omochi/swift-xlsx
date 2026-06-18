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

    @Flag(help: "Write extracted files without formatting XML files.")
    public var raw = false

    public init() {}

    public func run() throws {
        let inputURL = URL(fileURLWithPath: input)
        let outputURL = output.map(URL.init(fileURLWithPath:)) ?? XLSXToolOutputURL.extractDefault(for: inputURL)
        let data = try Data(contentsOf: inputURL)
        let package = try OPCPackage(data: data)
        try write(package: package, toDirectoryURL: outputURL)
    }

    private func write(package: OPCPackage, toDirectoryURL directoryURL: URL) throws {
        var isDirectory: ObjCBool = false
        if FileManager.default.fileExists(atPath: directoryURL.path, isDirectory: &isDirectory) {
            guard isDirectory.boolValue else {
                throw OPCError.entryIsNotDirectory(directoryURL.path)
            }
            try FileManager.default.removeItem(at: directoryURL)
        }
        try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)

        for entry in package.allFileEntries() {
            let url = fileURL(for: entry.path, relativeTo: directoryURL)
            switch entry.content {
            case .directory:
                try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)

            case let .file(data):
                let parentURL = url.deletingLastPathComponent()
                try FileManager.default.createDirectory(at: parentURL, withIntermediateDirectories: true)

                var isDirectory: ObjCBool = false
                if FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory), isDirectory.boolValue {
                    throw OPCError.conflictingEntry(url.path)
                }
                try outputData(data, for: entry.path).write(to: url, options: .atomic)
            }
        }
    }

    private func outputData(_ data: Data, for path: OPCFilePath) -> Data {
        guard !raw, isFormattedXMLFile(path: path),
              let document = try? XMLDocument(data: data)
        else {
            return data
        }
        return Data(document.xmlString(pretty: true).utf8)
    }

    private func isFormattedXMLFile(path: OPCFilePath) -> Bool {
        guard let fileName = path.components.last?.lowercased() else {
            return false
        }
        return fileName.hasSuffix(".xml") || fileName.hasSuffix(".rels")
    }

    private func fileURL(for path: OPCFilePath, relativeTo directoryURL: URL) -> URL {
        path.components.reduce(directoryURL) { url, component in
            url.appendingPathComponent(component)
        }
    }
}
