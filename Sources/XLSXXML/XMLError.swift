public enum XMLError: Error & Equatable {
    case missingRootElement
    case missingNamespacePrefix(String)
}
