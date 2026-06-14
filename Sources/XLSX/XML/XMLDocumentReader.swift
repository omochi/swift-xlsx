import Foundation
import SAXParser
import XMLCore

public enum XMLDocumentReader {
    public static func parse(_ data: Data) throws -> XMLDocument {
        var parser = SAXParser(handler: XMLDocumentBuilder())
        try parser.parse(bytes: Array(data).span)
        return parser.handler.document
    }
}
