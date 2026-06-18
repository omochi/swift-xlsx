import Foundation

public struct OPCPackage: Sendable {
    public init() {
        self.root = OPCPackageNodeID(rawValue: 0)
        self.nodes = [
            .directory(OPCPackageDirectoryNode())
        ]
    }

    public init(directoryURL: URL) throws {
        self = try OPCPackage(fileEntries: OPCFileSystem.readDirectory(at: directoryURL))
    }

    public init(data: Data) throws {
        self = try OPCPackage(fileEntries: ZIPArchive.decode(data))
    }

    public init(fileEntries: [OPCFileEntry]) throws {
        self.init()

        for entry in fileEntries {
            switch entry.content {
            case .directory:
                _ = try ensureDirectory(at: entry.path)

            case let .file(data):
                try insertFile(data: data, at: entry.path)
            }
        }
    }

    public var nodes: [OPCPackageNode]
    public var root: OPCPackageNodeID

    public func node(at path: OPCFilePath) throws -> OPCPackageNode {
        guard let id = nodeID(at: path) else {
            throw OPCError.entryNotFound(path.description)
        }
        return node(for: id)
    }

    public func node(for id: OPCPackageNodeID) -> OPCPackageNode {
        nodes[id.rawValue]
    }

    public func nodeID(at path: OPCFilePath) -> OPCPackageNodeID? {
        var current = root

        for component in path.components {
            guard case let .directory(directory) = node(for: current),
                  let next = directory.entryDictionary[component]
            else {
                return nil
            }

            current = next
        }

        return current
    }

    public func data(at path: OPCFilePath) -> Data? {
        guard let id = nodeID(at: path),
              case let .file(file) = node(for: id)
        else {
            return nil
        }
        return file.data
    }

    public func fileWithPath<File>(
        _ type: File.Type,
        at path: OPCFilePath,
        read: (XMLDocument) throws -> File
    ) throws -> OPCPathWithFile<File>? {
        guard let data = data(at: path) else {
            return nil
        }
        return try OPCPathWithFile(
            path: path,
            file: read(XMLDocument(data: data))
        )
    }

    public func data() throws -> Data {
        try ZIPArchive.encode(fileEntries())
    }

    public func childNames(in directoryPath: OPCFilePath) throws -> [String] {
        guard let id = nodeID(at: directoryPath) else {
            throw OPCError.entryNotFound(directoryPath.description)
        }
        guard case let .directory(directory) = node(for: id) else {
            throw OPCError.entryIsNotDirectory(directoryPath.description)
        }
        return directory.children.map(\.0)
    }

    public func fileEntries() -> [OPCFileEntry] {
        var entries: [OPCFileEntry] = []
        collectEntries(from: root, components: [], into: &entries)
        return entries
    }

    public func allFilePaths() -> [OPCFilePath] {
        fileEntries().compactMap { entry in
            guard case .file = entry.content else {
                return nil
            }
            return entry.path
        }
    }

    public mutating func insertFile(data: Data, at path: OPCFilePath) throws {
        guard let fileName = path.components.last else {
            throw OPCError.invalidPath(path.description)
        }

        let directoryID = try ensureDirectory(components: path.components.dropLast())
        guard case var .directory(directory) = node(for: directoryID) else {
            throw OPCError.entryIsNotDirectory(path.description)
        }

        if let existingID = directory.entryDictionary[fileName] {
            guard case .file = node(for: existingID) else {
                throw OPCError.conflictingEntry(path.description)
            }
            nodes[existingID.rawValue] = .file(OPCPackageFileNode(data: data))
            return
        }

        let fileID = OPCPackageNodeID(rawValue: nodes.count)
        nodes.append(.file(OPCPackageFileNode(data: data)))
        directory.entryDictionary[fileName] = fileID
        nodes[directoryID.rawValue] = .directory(directory)
    }

    public mutating func insertFile(xmlDocument: XMLDocument, at path: OPCFilePath) throws {
        try insertFile(data: xmlDocument.data, at: path)
    }

    public mutating func insertXMLFile<File>(
        pathWithFile: OPCPathWithFile<File>,
        makeXMLDocument: (File) throws -> XMLDocument
    ) throws {
        try insertFile(
            xmlDocument: try makeXMLDocument(pathWithFile.file),
            at: pathWithFile.path
        )
    }

    public mutating func insertFile(_ pathWithFile: OPCOpaquePathWithFile) throws {
        try insertFile(data: pathWithFile.file.data(), at: pathWithFile.path)
    }

    public mutating func ensureDirectory(at path: OPCFilePath) throws -> OPCPackageNodeID {
        try ensureDirectory(components: path.components[...])
    }

    public func write(toDirectoryURL directoryURL: URL) throws {
        try OPCFileSystem.writeDirectory(fileEntries(), to: directoryURL)
    }

    private mutating func ensureDirectory(components: ArraySlice<String>) throws -> OPCPackageNodeID {
        var current = root

        for component in components {
            guard case var .directory(directory) = node(for: current) else {
                throw OPCError.entryIsNotDirectory(component)
            }

            if let existing = directory.entryDictionary[component] {
                guard case .directory = node(for: existing) else {
                    throw OPCError.conflictingEntry(component)
                }
                current = existing
                continue
            }

            let newID = OPCPackageNodeID(rawValue: nodes.count)
            nodes.append(.directory(OPCPackageDirectoryNode()))
            directory.entryDictionary[component] = newID
            nodes[current.rawValue] = .directory(directory)
            current = newID
        }

        return current
    }

    private func collectEntries(from id: OPCPackageNodeID, components: [String], into entries: inout [OPCFileEntry]) {
        switch node(for: id) {
        case let .file(file):
            entries.append(OPCFileEntry(
                path: OPCFilePath(components: components),
                content: .file(file.data)
            ))
        case let .directory(directory):
            if !components.isEmpty {
                entries.append(OPCFileEntry(
                    path: OPCFilePath(components: components),
                    content: .directory(directory.children.map(\.0))
                ))
            }
            for (name, childID) in directory.children {
                collectEntries(from: childID, components: components + [name], into: &entries)
            }
        }
    }

}
