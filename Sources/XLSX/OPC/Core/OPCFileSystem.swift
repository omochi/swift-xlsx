import Foundation

private var fileManager: FileManager { .default }

enum OPCFileSystem {
    static func readDirectory(at directoryURL: URL) throws -> [OPCFileEntry] {
        try readDirectory(at: directoryURL, components: [])
    }

    static func writeDirectory(_ entries: [OPCFileEntry], to directoryURL: URL) throws {
        var isDirectory: ObjCBool = false
        if fileManager.fileExists(atPath: directoryURL.path, isDirectory: &isDirectory) {
            guard isDirectory.boolValue else {
                throw OPCError.entryIsNotDirectory(directoryURL.path)
            }
        } else {
            try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        }

        for entry in entries {
            let url = fileURL(for: entry.path, relativeTo: directoryURL)
            switch entry.content {
            case .directory:
                try fileManager.createDirectory(at: url, withIntermediateDirectories: true)

            case let .file(data):
                let parentURL = url.deletingLastPathComponent()
                try fileManager.createDirectory(at: parentURL, withIntermediateDirectories: true)

                var isDirectory: ObjCBool = false
                if fileManager.fileExists(atPath: url.path, isDirectory: &isDirectory), isDirectory.boolValue {
                    throw OPCError.conflictingEntry(url.path)
                }
                try data.write(to: url, options: .atomic)
            }
        }
    }

    private static func readDirectory(
        at directoryURL: URL,
        components: [String]
    ) throws -> [OPCFileEntry] {
        var isDirectory: ObjCBool = false
        guard fileManager.fileExists(atPath: directoryURL.path, isDirectory: &isDirectory) else {
            throw OPCError.entryNotFound(directoryURL.path)
        }
        guard isDirectory.boolValue else {
            throw OPCError.entryIsNotDirectory(directoryURL.path)
        }

        let childURLs = try fileManager.contentsOfDirectory(
            at: directoryURL,
            includingPropertiesForKeys: [.isDirectoryKey, .isRegularFileKey, .isSymbolicLinkKey],
            options: []
        ).sorted(by: { $0.lastPathComponent < $1.lastPathComponent })

        var entries: [OPCFileEntry] = []
        if !components.isEmpty {
            entries.append(OPCFileEntry(
                path: OPCFilePath(components: components),
                content: .directory(childURLs.map(\.lastPathComponent))
            ))
        }

        for childURL in childURLs {
            let name = childURL.lastPathComponent
            let childComponents = components + [name]
            let path = OPCFilePath(components: childComponents)
            let resourceValues = try childURL.resourceValues(forKeys: [
                .isDirectoryKey,
                .isRegularFileKey,
                .isSymbolicLinkKey,
            ])

            if resourceValues.isSymbolicLink == true {
                throw OPCError.unsupportedFileSystemEntry(childURL.path)
            }
            if resourceValues.isDirectory == true {
                entries.append(contentsOf: try readDirectory(at: childURL, components: childComponents))
                continue
            }
            if resourceValues.isRegularFile == true {
                entries.append(OPCFileEntry(
                    path: path,
                    content: .file(try Data(contentsOf: childURL))
                ))
                continue
            }

            throw OPCError.unsupportedFileSystemEntry(childURL.path)
        }

        return entries
    }

    private static func fileURL(for path: OPCFilePath, relativeTo directoryURL: URL) -> URL {
        path.components.reduce(directoryURL) { url, component in
            url.appendingPathComponent(component)
        }
    }
}
