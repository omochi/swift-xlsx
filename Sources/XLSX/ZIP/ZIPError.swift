enum ZIPError: Error & Equatable {
    case invalidArchive
    case archiveTooLarge
    case unsupportedFeature(String)
    case compressionFailed
    case decompressionFailed
}
