import Foundation

public final class XLDocument {
    public convenience init() {
        try! self.init(package: OPCPackage())
    }

    public init(package: XLDocumentPackage) {
        self.package = package
    }

    public convenience init(package: OPCPackage) throws {
        try self.init(package: XLDocumentPackage(package: package))
    }

    public var package: XLDocumentPackage

    public var workbook: XLWorkbookFile {
        get {
            package.workbook.file
        }
        set {
            package.workbook.file = newValue
        }
    }

    public static func open(_ url: URL) throws -> XLDocument {
        try XLDocument(package: OPCPackage(data: Data(contentsOf: url)))
    }

    public func save(to url: URL) throws {
        let data = try package.makeOPCPackage().data()
        try data.write(to: url, options: .atomic)
    }
}
