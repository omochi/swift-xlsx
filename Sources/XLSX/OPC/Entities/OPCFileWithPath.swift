import MemberwiseInit

@MemberwiseInit(.public)
public struct OPCFileWithPath<File: OPCFile> {
    public var path: OPCFilePath
    public var file: File
}
