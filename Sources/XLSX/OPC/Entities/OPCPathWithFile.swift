import MemberwiseInit

@MemberwiseInit(.public)
public struct OPCPathWithFile<File: OPCFile> {
    public var path: OPCFilePath
    public var file: File

    public func clone(_ cloneFile: (File) -> File) -> Self {
        OPCPathWithFile(path: path, file: cloneFile(file))
    }
}
