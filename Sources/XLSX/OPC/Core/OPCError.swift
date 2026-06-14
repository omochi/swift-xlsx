public enum OPCError: Error & Equatable {
    case invalidPath(String)
    case entryNotFound(String)
    case entryIsNotDirectory(String)
    case entryIsNotFile(String)
    case conflictingEntry(String)
    case unsupportedFileSystemEntry(String)
}
