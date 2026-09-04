import Foundation

public struct XLDocument {
    public init() {
        self.init(package: XLDocumentPackage())
    }

    public init(package: XLDocumentPackage) {
        self.package = package
    }

    public init(opcPackage: OPCPackage) throws {
        try self.init(package: XLDocumentPackage(opcPackage: opcPackage))
    }

    public init(data: Data) throws {
        try self.init(opcPackage: OPCPackage(data: data))
    }

    public var package: XLDocumentPackage

    public var workbook: XLWorkbook {
        XLWorkbook(package: package)
    }

    public static func open(url: URL) throws -> XLDocument {
        try XLDocument(data: Data(contentsOf: url))
    }

    public func data() throws -> Data {
        try package.clone().makeOPCPackage().data()
    }

    public func save(to url: URL) throws {
        try data().write(to: url, options: .atomic)
    }
}
