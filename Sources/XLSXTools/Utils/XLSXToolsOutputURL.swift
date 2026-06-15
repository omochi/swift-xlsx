import Foundation

enum XLSXToolsOutputURL {
    static func extractDefault(for inputURL: URL) -> URL {
        let baseURL = inputURL.deletingPathExtension()
        if baseURL.path == inputURL.path {
            return inputURL.appendingPathExtension("contents")
        }
        return baseURL
    }

    static func packDefault(for inputURL: URL) -> URL {
        inputURL.appendingPathExtension("xlsx")
    }
}
