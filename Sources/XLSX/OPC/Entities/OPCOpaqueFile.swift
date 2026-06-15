import MemberwiseInit
import Foundation

@MemberwiseInit(.public)
public struct OPCOpaqueFile {
    public var path: OPCFilePath
    public var data: Data
}
