import Foundation

public final class XLDocumentPackage {
    public init() {
        self.contentTypes = OPCFileWithPath(
            path: try! OPCFilePath(string: "/[Content_Types].xml"),
            file: OPCContentTypesFile()
        )
        self.packageRels = OPCFileWithPath(
            path: try! OPCRelsFile.path(for: .packageRoot),
            file: OPCRelsFile()
        )
        self.workbook = OPCFileWithPath(
            path: try! OPCFilePath(string: "/xl/workbook.xml"),
            file: XLWorkbookFile()
        )
        self.workbookRels = OPCFileWithPath(
            path: try! OPCFilePath(string: "/xl/_rels/workbook.xml.rels"),
            file: OPCRelsFile()
        )
        self.opaqueFiles = []
    }

    public init(
        contentTypes: OPCFileWithPath<OPCContentTypesFile>,
        packageRels: OPCFileWithPath<OPCRelsFile>,
        workbook: OPCFileWithPath<XLWorkbookFile>,
        workbookRels: OPCFileWithPath<OPCRelsFile>,
        opaqueFiles: [OPCOpaqueFileWithPath]
    ) {
        self.contentTypes = contentTypes
        self.packageRels = packageRels
        self.workbook = workbook
        self.workbookRels = workbookRels
        self.opaqueFiles = opaqueFiles
    }

    init(opcPackage: OPCPackage) throws {
        var consumedPaths: Set<OPCFilePath> = []

        let contentTypes = try Self.readFile(
            OPCContentTypesFile.self,
            from: opcPackage,
            at: OPCFilePath(string: "/[Content_Types].xml"),
            default: OPCContentTypesFile(),
            consumedPaths: &consumedPaths
        )

        let packageRels = try Self.readFile(
            OPCRelsFile.self,
            from: opcPackage,
            at: try OPCRelsFile.path(for: .packageRoot),
            default: OPCRelsFile(),
            consumedPaths: &consumedPaths
        )

        let workbook = try Self.readFile(
            XLWorkbookFile.self,
            from: opcPackage,
            at: try Self.workbookPath(in: packageRels.file),
            default: XLWorkbookFile(),
            consumedPaths: &consumedPaths
        )

        let workbookRels = try Self.readFile(
            OPCRelsFile.self,
            from: opcPackage,
            at: try OPCRelsFile.path(for: workbook.path),
            default: OPCRelsFile(),
            consumedPaths: &consumedPaths
        )

        workbook.file.worksheetFromID = try Self.worksheets(
            in: opcPackage,
            for: workbook.file.sheets,
            workbookPath: workbook.path,
            workbookRels: workbookRels.file,
            consumedPaths: &consumedPaths
        )

        self.contentTypes = contentTypes
        self.packageRels = packageRels
        self.workbook = workbook
        self.workbookRels = workbookRels
        self.opaqueFiles = Self.opaqueFiles(in: opcPackage, excluding: consumedPaths)
    }

    public var contentTypes: OPCFileWithPath<OPCContentTypesFile>
    public var packageRels: OPCFileWithPath<OPCRelsFile>
    public var workbook: OPCFileWithPath<XLWorkbookFile>
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

    func makeOPCPackage() throws -> OPCPackage {
        var contentTypes = contentTypes
        var packageRels = packageRels
        let workbook = workbook
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
            if !Self.containsOpaqueFile(at: file.path, in: opaqueFiles) {
                try package.insertFile(file)
            }
        }
        if !Self.containsOpaqueFile(at: sharedStringsPath, in: opaqueFiles) {
            try package.insertFile(
                data: Data(Self.sharedStringsXML.utf8),
                at: sharedStringsPath
            )
        }
        Self.registerRequiredContentTypes(
            in: &contentTypes.file,
            workbookPath: workbook.path,
            workbookContentTypeOverrides: workbookItems.contentTypeOverrides,
            sharedStringsPath: sharedStringsPath
        )
        try package.insertFile(contentTypes)

        return package
    }

    private static func readFile<File: OPCFile>(
        _ type: File.Type,
        from package: OPCPackage,
        at path: OPCFilePath,
        default defaultFile: @autoclosure () -> File,
        consumedPaths: inout Set<OPCFilePath>
    ) throws -> OPCFileWithPath<File> {
        guard let fileWithPath = try package.fileWithPath(type, at: path) else {
            return OPCFileWithPath(path: path, file: defaultFile())
        }

        consumedPaths.insert(path)
        return fileWithPath
    }

    private static func opaqueFiles(
        in package: OPCPackage,
        excluding consumedPaths: Set<OPCFilePath>
    ) -> [OPCOpaqueFileWithPath] {
        package.allFilePaths().compactMap { path in
            guard !consumedPaths.contains(path) else {
                return nil
            }
            return try? package.fileWithPath(OPCOpaqueFile.self, at: path)
        }
    }

    private static func worksheets(
        in package: OPCPackage,
        for sheets: [XLWorkbookFileSheet],
        workbookPath: OPCFilePath,
        workbookRels: OPCRelsFile,
        consumedPaths: inout Set<OPCFilePath>
    ) throws -> [Int: OPCFileWithPath<XLWorksheetFile>] {
        var worksheets: [Int: OPCFileWithPath<XLWorksheetFile>] = [:]
        for sheet in sheets {
            guard let relationship = workbookRels.relationships.first(where: { $0.id == sheet.relationshipID }),
                  relationship.type == XMLNamespaceURI.worksheet.string
            else {
                continue
            }
            let path = try OPCFilePath(string: relationship.target).resolved(relativeTo: workbookPath)
            worksheets[sheet.sheetID] = try Self.readFile(
                XLWorksheetFile.self,
                from: package,
                at: path,
                default: XLWorksheetFile(),
                consumedPaths: &consumedPaths
            )
        }
        return worksheets
    }

    private static func containsOpaqueFile(
        at path: OPCFilePath,
        in opaqueFiles: [OPCOpaqueFileWithPath]
    ) -> Bool {
        opaqueFiles.contains { $0.path == path }
    }

    private static func registerRequiredContentTypes(
        in contentTypes: inout OPCContentTypesFile,
        workbookPath: OPCFilePath,
        workbookContentTypeOverrides: [OPCFilePath: String],
        sharedStringsPath: OPCFilePath
    ) {
        contentTypes.ensureDefault(
            extension: "rels",
            contentType: OPCContentTypes.relationships
        )
        contentTypes.ensureDefault(
            extension: "xml",
            contentType: OPCContentTypes.xml
        )
        contentTypes.ensureOverride(
            partName: workbookPath,
            contentType: OPCContentTypes.workbook
        )
        for (partName, contentType) in workbookContentTypeOverrides {
            contentTypes.ensureOverride(
                partName: partName,
                contentType: contentType
            )
        }
        contentTypes.ensureOverride(
            partName: sharedStringsPath,
            contentType: OPCContentTypes.sharedStrings
        )
    }

    private static func workbookPath(in packageRels: OPCRelsFile) throws -> OPCFilePath {
        if let relationship = packageRels.relationships.first(where: { $0.type == XMLNamespaceURI.officeDocument.string }) {
            return try OPCFilePath(string: relationship.target).resolved(relativeTo: .packageRoot)
        }
        return try OPCFilePath(string: "/xl/workbook.xml")
    }
}
