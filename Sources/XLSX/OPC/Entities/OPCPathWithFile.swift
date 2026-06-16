import MemberwiseInit

@MemberwiseInit(.public)
public struct OPCPathWithFile<File: OPCFile> {
    public var path: OPCFilePath
    public var file: File
}
