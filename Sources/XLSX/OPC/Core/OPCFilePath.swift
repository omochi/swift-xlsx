import Foundation

public struct OPCFilePath: Sendable & Hashable & CustomStringConvertible {
    public init(isAbsolute: Bool = true, components: [String]) {
        self.isAbsolute = isAbsolute
        self.components = components
    }

    public init(string: String) throws {
        if string.contains("\\") {
            throw OPCError.invalidPath(string)
        }

        self.isAbsolute = string.hasPrefix("/")
        var componentString = isAbsolute ? String(string.dropFirst()) : string
        while componentString.hasSuffix("/") {
            componentString.removeLast()
        }
        if componentString.isEmpty {
            self.components = []
            return
        }

        self.components = componentString.split(separator: "/").map(String.init)
    }

    public var isAbsolute: Bool
    public var components: [String]

    public func normalized() throws -> OPCFilePath {
        var normalizedComponents: [String] = []

        for component in components {
            switch component {
            case ".":
                continue
            case "..":
                if let last = normalizedComponents.last, last != ".." {
                    normalizedComponents.removeLast()
                } else if isAbsolute {
                    throw OPCError.invalidPath(description)
                } else {
                    normalizedComponents.append(component)
                }
            default:
                normalizedComponents.append(component)
            }
        }

        return OPCFilePath(isAbsolute: isAbsolute, components: normalizedComponents)
    }

    public func resolved(relativeTo path: OPCFilePath) throws -> OPCFilePath {
        if isAbsolute {
            return try normalized()
        }

        let directoryComponents = path.components.dropLast()
        return try OPCFilePath(
            isAbsolute: path.isAbsolute,
            components: Array(directoryComponents) + components
        ).normalized()
    }

    public var description: String {
        var path = ""
        if isAbsolute {
            path += "/"
        }
        path += components.joined(separator: "/")
        return path
    }
}
