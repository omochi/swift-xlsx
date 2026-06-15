import Foundation

public protocol OPCXMLFile: OPCFile {
    init(xmlDocument: XMLDocument) throws
    func xmlDocument() throws -> XMLDocument
}

extension OPCXMLFile {
    public init(data: Data) throws {
        try self.init(xmlDocument: XMLDocumentReader.parse(data))
    }

    public func data() throws -> Data {
        try xmlDocument().data()
    }
}
