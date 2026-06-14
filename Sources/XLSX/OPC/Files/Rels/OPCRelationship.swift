import MemberwiseInit

@MemberwiseInit(.public)
public struct OPCRelationship: Sendable {
    public var id: String
    public var type: String
    public var target: String

    public func targetPath(relativeTo sourcePath: OPCFilePath) throws -> OPCFilePath {
        if target.hasPrefix("/") {
            return try OPCFilePath(string: target)
        }

        let directoryComponents = sourcePath.components.dropLast()
        let rawComponents = Array(directoryComponents) + target.split(separator: "/").map(String.init)
        var normalizedComponents: [String] = []

        for component in rawComponents {
            switch component {
            case "", ".":
                continue
            case "..":
                guard !normalizedComponents.isEmpty else {
                    throw OPCError.invalidPath(target)
                }
                normalizedComponents.removeLast()
            default:
                normalizedComponents.append(component)
            }
        }

        return try OPCFilePath(string: normalizedComponents.joined(separator: "/"))
    }
}
