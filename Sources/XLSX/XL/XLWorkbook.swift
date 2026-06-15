import Foundation

public struct XLWorkbook {
    public init() {
        let workbookPath = try! OPCFilePath(string: "/xl/workbook.xml")

        self.contentTypes = OPCContentTypesFile()
        self.packageRels = OPCRelsFile()
        self.workbookPath = workbookPath
        self.workbook = try! XLWorkbookFile.default(path: workbookPath)
        self.workbookRels = OPCRelsFile()
        self.opaqueFiles = []
    }

    init(package: OPCPackage) throws {
        var consumedPaths: Set<OPCFilePath> = []

        let contentTypesPath = try OPCFilePath(string: "/[Content_Types].xml")
        let contentTypesData = try? package.data(at: contentTypesPath)
        if contentTypesData != nil {
            consumedPaths.insert(contentTypesPath)
        }
        let contentTypes = try OPCContentTypesFile(data: contentTypesData)

        let packageRelsPath = try OPCFilePath(string: "/_rels/.rels")
        let packageRelsData = try? package.data(at: packageRelsPath)
        if packageRelsData != nil {
            consumedPaths.insert(packageRelsPath)
        }
        let packageRels = try OPCRelsFile(data: packageRelsData)

        let workbookPath = try packageRels.workbookPath()
        let workbookData = try? package.data(at: workbookPath)
        if workbookData != nil {
            consumedPaths.insert(workbookPath)
        }
        let workbook = try workbookData.map {
            try XLWorkbookFile(path: workbookPath, data: $0)
        } ?? XLWorkbookFile.default(path: workbookPath)

        let workbookRelsPath = try OPCRelsFile.path(for: workbookPath)
        let workbookRelsData = try? package.data(at: workbookRelsPath)
        if workbookRelsData != nil {
            consumedPaths.insert(workbookRelsPath)
        }
        let workbookRels = try OPCRelsFile(data: workbookRelsData)

        let opaqueFiles = try Self.opaqueFiles(
            in: package,
            consumedPaths: consumedPaths
        )

        self.contentTypes = contentTypes
        self.packageRels = packageRels
        self.workbookPath = workbookPath
        self.workbook = workbook
        self.workbookRels = workbookRels
        self.opaqueFiles = opaqueFiles
    }

    var contentTypes: OPCContentTypesFile
    var packageRels: OPCRelsFile
    var workbookPath: OPCFilePath
    var workbook: XLWorkbookFile
    var workbookRels: OPCRelsFile
    var opaqueFiles: [OPCOpaqueFile]

    public static func open(_ url: URL) throws -> XLWorkbook {
        try XLWorkbook(package: OPCPackage(data: Data(contentsOf: url)))
    }

    public func save(to url: URL) throws {
        var workbook = self
        let package = try XLHelloWorldWriter.package(for: &workbook)
        let data = try package.data()
        try data.write(to: url, options: .atomic)
    }

    private static func opaqueFiles(
        in package: OPCPackage,
        consumedPaths: Set<OPCFilePath>
    ) throws -> [OPCOpaqueFile] {
        try package.allFilePaths().compactMap { path in
            guard !consumedPaths.contains(path) else {
                return nil
            }
            return OPCOpaqueFile(path: path, data: try package.data(at: path))
        }
    }
}

private extension OPCRelsFile {
    func workbookPath() throws -> OPCFilePath {
        if let relationship = relationships.first(where: { $0.type == XLXMLURIs.officeDocument }) {
            return try OPCFilePath(string: relationship.target).resolved(relativeTo: OPCFilePath(string: "/"))
        }
        return try OPCFilePath(string: "/xl/workbook.xml")
    }
}
