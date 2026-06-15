import Foundation

struct XLWorkbookFile {
    var contentTypes: OPCContentTypesFile
    var packageRels: OPCRelsFile
    var workbookPath: OPCFilePath
    var workbook: XLWorkbookXMLFile
    var workbookRels: OPCRelsFile
    var opaqueFiles: [OPCOpaqueFile]

    init() throws {
        let workbookPath = try OPCFilePath(string: "/xl/workbook.xml")

        self.contentTypes = OPCContentTypesFile()
        self.packageRels = OPCRelsFile()
        self.workbookPath = workbookPath
        self.workbook = try XLWorkbookXMLFile.default(path: workbookPath)
        self.workbookRels = OPCRelsFile()
        self.opaqueFiles = []
    }

    init(package: OPCPackage) throws {
        let contentTypesPath = try OPCFilePath(string: "/[Content_Types].xml")
        let contentTypes = try OPCContentTypesFile(data: try? package.data(at: contentTypesPath))
        let packageRelsPath = try OPCFilePath(string: "/_rels/.rels")
        let packageRels = try OPCRelsFile(data: try? package.data(at: packageRelsPath))
        let workbookPath = try Self.workbookPath(in: packageRels)
        let workbook = try Self.workbookFile(in: package, at: workbookPath)
        let workbookRelsPath = try OPCRelsFile.path(for: workbookPath)
        let workbookRels = try OPCRelsFile(data: try? package.data(at: workbookRelsPath))
        let opaqueFiles = try Self.opaqueFiles(
            in: package,
            consumedPaths: Self.consumedPaths(
                packageRelsPath: packageRelsPath,
                workbookPath: workbookPath,
                workbookRelsPath: workbookRelsPath,
                workbookRels: workbookRels
            )
        )

        self.packageRels = packageRels
        self.contentTypes = contentTypes
        self.workbookPath = workbookPath
        self.workbook = workbook
        self.workbookRels = workbookRels
        self.opaqueFiles = opaqueFiles
    }

    private static func workbookPath(in packageRels: OPCRelsFile) throws -> OPCFilePath {
        if let relationship = packageRels.relationships.first(where: { $0.type == XLXMLURIs.officeDocument }) {
            return try OPCFilePath(string: relationship.target).resolved(relativeTo: OPCFilePath(string: "/"))
        }
        return try OPCFilePath(string: "/xl/workbook.xml")
    }

    private static func workbookFile(
        in package: OPCPackage,
        at path: OPCFilePath
    ) throws -> XLWorkbookXMLFile {
        guard let data = try? package.data(at: path) else {
            return try .default(path: path)
        }
        return try XLWorkbookXMLFile(path: path, data: data)
    }

    private static func consumedPaths(
        packageRelsPath: OPCFilePath,
        workbookPath: OPCFilePath,
        workbookRelsPath: OPCFilePath,
        workbookRels: OPCRelsFile
    ) throws -> Set<OPCFilePath> {
        var paths: Set<OPCFilePath> = [
            try OPCFilePath(string: "/[Content_Types].xml"),
            packageRelsPath,
            workbookPath,
            workbookRelsPath,
        ]

        for relationship in workbookRels.relationships {
            guard relationship.type == XLXMLURIs.worksheet
                || relationship.type == XLXMLURIs.sharedStrings
            else {
                continue
            }
            paths.insert(try OPCFilePath(string: relationship.target).resolved(relativeTo: workbookPath))
        }

        return paths
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
