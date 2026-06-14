public enum OPCPackageNode: Sendable {
    case file(OPCPackageFileNode)
    case directory(OPCPackageDirectoryNode)
}
