import Foundation

public struct XLDocument {
    public init() {
        try! self.init(package: OPCPackage())
    }

    init(package: OPCPackage) throws {
        var consumedPaths: Set<OPCFilePath> = []

        let contentTypesPath = try OPCFilePath(string: "/[Content_Types].xml")
        let contentTypesData = package.data(at: contentTypesPath)
        if contentTypesData != nil {
            consumedPaths.insert(contentTypesPath)
        }
        let contentTypes = try OPCContentTypesFile(data: contentTypesData)

        let packageRelsPath = try OPCRelsFile.path(for: OPCFilePath(string: "/"))
        let packageRelsData = package.data(at: packageRelsPath)
        if packageRelsData != nil {
            consumedPaths.insert(packageRelsPath)
        }
        let packageRels = try OPCRelsFile(data: packageRelsData)

        let workbookPath = try packageRels.workbookPath()
        let workbookData = package.data(at: workbookPath)
        if workbookData != nil {
            consumedPaths.insert(workbookPath)
        }
        let workbook = try XLWorkbook(data: workbookData)

        let workbookRelsPath = try OPCRelsFile.path(for: workbookPath)
        let workbookRelsData = package.data(at: workbookRelsPath)
        if workbookRelsData != nil {
            consumedPaths.insert(workbookRelsPath)
        }
        let workbookRels = try OPCRelsFile(data: workbookRelsData)

        let opaqueFiles = package.opaqueFiles(excluding: consumedPaths)

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
    var workbook: XLWorkbook
    var workbookRels: OPCRelsFile
    var opaqueFiles: [OPCOpaqueFile]

    public static func open(_ url: URL) throws -> XLDocument {
        try XLDocument(package: OPCPackage(data: Data(contentsOf: url)))
    }

    public func save(to url: URL) throws {
        var document = self
        let package = try XLHelloWorldWriter.package(for: &document)
        let data = try package.data()
        try data.write(to: url, options: .atomic)
    }

}

private extension OPCPackage {
    func opaqueFiles(excluding consumedPaths: Set<OPCFilePath>) -> [OPCOpaqueFile] {
        allFilePaths().compactMap { path in
            guard !consumedPaths.contains(path) else {
                return nil
            }
            guard let data = data(at: path) else {
                return nil
            }
            return OPCOpaqueFile(path: path, data: data)
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
