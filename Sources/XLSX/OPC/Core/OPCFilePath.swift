import MemberwiseInit
import Foundation

@MemberwiseInit(.public)
public struct OPCFilePath: Sendable & Hashable & CustomStringConvertible {
    public init(string: String) throws {
        if string.contains("\\") {
            throw OPCError.invalidPath(string)
        }

        let normalized = string.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        if normalized.isEmpty {
            self.components = []
            return
        }

        let components = normalized.split(separator: "/").map(String.init)
        if components.contains(where: { $0.isEmpty || $0 == "." || $0 == ".." }) {
            throw OPCError.invalidPath(string)
        }

        self.components = components
    }

    public var components: [String]

    public var description: String {
        "/" + components.joined(separator: "/")
    }
}
