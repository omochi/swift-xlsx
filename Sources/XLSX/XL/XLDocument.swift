import Foundation

public struct XLDocument {
    public init() {
        try! self.init(package: OPCPackage())
    }

    public init(package: OPCPackage) throws {
        var consumedPaths: Set<OPCFilePath> = []

        let contentTypes = try Self.readFile(
            OPCContentTypesFile.self,
            from: package,
            at: OPCFilePath(string: "/[Content_Types].xml"),
            default: OPCContentTypesFile(),
            consumedPaths: &consumedPaths
        )

        let packageRels = try Self.readFile(
            OPCRelsFile.self,
            from: package,
            at: try OPCRelsFile.path(for: .packageRoot),
            default: OPCRelsFile(),
            consumedPaths: &consumedPaths
        )

        var workbook = try Self.readFile(
            XLWorkbook.self,
            from: package,
            at: try Self.workbookPath(in: packageRels.file),
            default: XLWorkbook(),
            consumedPaths: &consumedPaths
        )

        let workbookRels = try Self.readFile(
            OPCRelsFile.self,
            from: package,
            at: try OPCRelsFile.path(for: workbook.path),
            default: OPCRelsFile(),
            consumedPaths: &consumedPaths
        )

        workbook.file.worksheets = try Self.worksheets(
            in: package,
            for: workbook.file.sheets,
            workbookPath: workbook.path,
            workbookRels: workbookRels.file,
            consumedPaths: &consumedPaths
        )

        let opaqueFiles = Self.opaqueFiles(in: package, excluding: consumedPaths)

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
        for sheets: [XLWorkbookSheet],
        workbookPath: OPCFilePath,
        workbookRels: OPCRelsFile,
        consumedPaths: inout Set<OPCFilePath>
    ) throws -> [Int: OPCFileWithPath<XLWorksheet>] {
        var worksheets: [Int: OPCFileWithPath<XLWorksheet>] = [:]
        for sheet in sheets {
            guard let relationship = workbookRels.relationships.first(where: { $0.id == sheet.relationshipID }) else {
                continue
            }
            let path = try OPCFilePath(string: relationship.target).resolved(relativeTo: workbookPath)
            worksheets[sheet.sheetID] = try Self.readFile(
                XLWorksheet.self,
                from: package,
                at: path,
                default: XLWorksheet(),
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
