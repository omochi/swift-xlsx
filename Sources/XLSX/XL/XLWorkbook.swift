import Foundation

public struct XLWorkbook {
    var file: XLWorkbookFile

    public init() {
        self.file = try! XLWorkbookFile()
    }

    init(file: XLWorkbookFile) {
        self.file = file
    }

    public static func open(_ url: URL) throws -> XLWorkbook {
        XLWorkbook(file: try XLWorkbookFile(package: OPCPackage(data: Data(contentsOf: url))))
    }

    public func save(to url: URL) throws {
        var file = file
        let package = try XLHelloWorldWriter.package(for: &file)
        let data = try package.data()
        try data.write(to: url, options: .atomic)
    }
}
