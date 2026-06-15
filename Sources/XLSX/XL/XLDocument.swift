import Foundation

public struct XLDocument {
    public init() {
        try! self.init(package: OPCPackage())
    }

    public init(package: OPCPackage) throws {
        var consumedPaths: Set<OPCFilePath> = []

        let contentTypes = try package.fileWithPath(
            OPCContentTypesFile.self,
            at: OPCFilePath(string: "/[Content_Types].xml"),
            default: OPCContentTypesFile(),
            consumedPaths: &consumedPaths
        )

        let packageRels = try package.fileWithPath(
            OPCRelsFile.self,
            at: try OPCRelsFile.path(for: .packageRoot),
            default: OPCRelsFile(),
            consumedPaths: &consumedPaths
        )

        var workbook = try package.fileWithPath(
            XLWorkbook.self,
            at: try packageRels.file.workbookPath(),
            default: XLWorkbook(),
            consumedPaths: &consumedPaths
        )

        let workbookRels = try package.fileWithPath(
            OPCRelsFile.self,
            at: try OPCRelsFile.path(for: workbook.path),
            default: OPCRelsFile(),
            consumedPaths: &consumedPaths
        )

        workbook.file.worksheets = try package.worksheets(
            for: workbook.file.sheets,
            workbookPath: workbook.path,
            workbookRels: workbookRels.file,
            consumedPaths: &consumedPaths
        )

        let opaqueFiles = package.opaqueFiles(excluding: consumedPaths)

        self.contentTypes = contentTypes
        self.packageRels = packageRels
        self.workbook = workbook
        self.workbookRels = workbookRels
        self.opaqueFiles = opaqueFiles
    }

    public var contentTypes: OPCFileWithPath<OPCContentTypesFile>
    public var packageRels: OPCFileWithPath<OPCRelsFile>
    public var workbook: OPCFileWithPath<XLWorkbook>
    public var workbookRels: OPCFileWithPath<OPCRelsFile>
    public var opaqueFiles: [OPCOpaqueFileWithPath]

    private static let sharedStringsXML = """
        <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
        <sst xmlns="\(XMLNamespaceURI.spreadsheet.string)" count="1" uniqueCount="1">
          <si>
            <t>hello world</t>
          </si>
        </sst>
        """

    public static func open(_ url: URL) throws -> XLDocument {
        try XLDocument(package: OPCPackage(data: Data(contentsOf: url)))
    }

    public func save(to url: URL) throws {
        let data = try makeOPCPackage().data()
        try data.write(to: url, options: .atomic)
    }

    private func makeOPCPackage() throws -> OPCPackage {
        var contentTypes = contentTypes
        var packageRels = packageRels
        var workbook = workbook
        var workbookRels = workbookRels
        let opaqueFiles = opaqueFiles

        packageRels.file.ensureRelationship(
            type: XMLNamespaceURI.officeDocument.string,
            target: workbook.path.relationshipTarget(relativeTo: .packageRoot)
        )
        let workbookItems = try workbook.file.packageItems(
            workbookPath: workbook.path,
            workbookRels: &workbookRels.file
        )
        let sharedStringsRelationship = workbookRels.file.ensureRelationship(
            type: XMLNamespaceURI.sharedStrings.string,
            target: "sharedStrings.xml"
        )
        let sharedStringsPath = try OPCFilePath(string: sharedStringsRelationship.target).resolved(relativeTo: workbook.path)

        var package = OPCPackage()
        for opaqueFile in opaqueFiles {
            try package.insertFile(opaqueFile)
        }
        try package.insertFile(packageRels)
        try package.insertFile(workbook)
        try package.insertFile(workbookRels)
        for file in workbookItems.files {
            if !opaqueFiles.contains(path: file.path) {
                try package.insertFile(file)
            }
        }
        if !opaqueFiles.contains(path: sharedStringsPath) {
            try package.insertFile(
                data: Data(Self.sharedStringsXML.utf8),
                at: sharedStringsPath
            )
        }
        contentTypes.file.ensureRequiredTypes(
            workbookPath: workbook.path,
            workbookContentTypeOverrides: workbookItems.contentTypeOverrides,
            sharedStringsPath: sharedStringsPath
        )
        try package.insertFile(contentTypes)

        return package
    }

}

private extension [OPCOpaqueFileWithPath] {
    func contains(path: OPCFilePath) -> Bool {
        contains { $0.path == path }
    }
}

private extension OPCPackage {
    func fileWithPath<File: OPCFile>(
        _ type: File.Type,
        at path: OPCFilePath,
        default defaultFile: @autoclosure () -> File,
        consumedPaths: inout Set<OPCFilePath>
    ) throws -> OPCFileWithPath<File> {
        guard let fileWithPath = try fileWithPath(type, at: path) else {
            return OPCFileWithPath(path: path, file: defaultFile())
        }

        consumedPaths.insert(path)
        return fileWithPath
    }

    func opaqueFiles(excluding consumedPaths: Set<OPCFilePath>) -> [OPCOpaqueFileWithPath] {
        allFilePaths().compactMap { path in
            guard !consumedPaths.contains(path) else {
                return nil
            }
            return try? fileWithPath(OPCOpaqueFile.self, at: path)
        }
    }

    func worksheets(
        for sheets: [XLWorkbookSheet],
        workbookPath: OPCFilePath,
        workbookRels: OPCRelsFile,
        consumedPaths: inout Set<OPCFilePath>
    ) throws -> [Int: OPCFileWithPath<XLWorksheet>] {
        var worksheets: [Int: OPCFileWithPath<XLWorksheet>] = [:]
        for sheet in sheets {
            guard let relationship = workbookRels.relationship(id: sheet.relationshipID) else {
                continue
            }
            let path = try OPCFilePath(string: relationship.target).resolved(relativeTo: workbookPath)
            worksheets[sheet.sheetID] = try fileWithPath(
                XLWorksheet.self,
                at: path,
                default: XLWorksheet(),
                consumedPaths: &consumedPaths
            )
        }
        return worksheets
    }
}

private extension OPCContentTypesFile {
    mutating func ensureRequiredTypes(
        workbookPath: OPCFilePath,
        workbookContentTypeOverrides: [OPCFilePath: String],
        sharedStringsPath: OPCFilePath
    ) {
        ensureDefault(
            extension: "rels",
            contentType: OPCContentTypes.relationships
        )
        ensureDefault(
            extension: "xml",
            contentType: OPCContentTypes.xml
        )
        ensureOverride(
            partName: workbookPath,
            contentType: OPCContentTypes.workbook
        )
        for (partName, contentType) in workbookContentTypeOverrides {
            ensureOverride(
                partName: partName,
                contentType: contentType
            )
        }
        ensureOverride(
            partName: sharedStringsPath,
            contentType: OPCContentTypes.sharedStrings
        )
    }
}

private extension OPCRelsFile {
    func relationship(id: String) -> OPCRelationship? {
        relationships.first { $0.id == id }
    }

    func workbookPath() throws -> OPCFilePath {
        if let relationship = relationships.first(where: { $0.type == XMLNamespaceURI.officeDocument.string }) {
            return try OPCFilePath(string: relationship.target).resolved(relativeTo: .packageRoot)
        }
        return try OPCFilePath(string: "/xl/workbook.xml")
    }
}
