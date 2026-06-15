import Foundation

public struct XLDocument {
    public init() {
        try! self.init(opcPackage: OPCPackage())
    }

    public init(package: XLDocumentPackage) {
        self.package = package
    }

    public init(opcPackage: OPCPackage) throws {
        try self.init(package: XLDocumentPackage(opcPackage: opcPackage))
    }

    public var package: XLDocumentPackage

    public var workbook: XLWorkbook {
        XLWorkbook(package: package)
    }

    public static func open(_ url: URL) throws -> XLDocument {
        try XLDocument(opcPackage: OPCPackage(data: Data(contentsOf: url)))
    }

    public func save(to url: URL) throws {
        let data = try package.makeOPCPackage().data()
        try data.write(to: url, options: .atomic)
    }
}
