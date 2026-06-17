import MemberwiseInit
import Foundation

@MemberwiseInit(.public)
public struct OPCFileEntry: Sendable {
    public enum Content: Sendable {
        case directory([String])
        case file(Data)
    }

    public var path: OPCFilePath
    public var content: Content
}
