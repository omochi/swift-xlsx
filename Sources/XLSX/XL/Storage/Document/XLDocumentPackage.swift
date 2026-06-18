import MemberwiseInit
import Foundation

@MemberwiseInit(.public)
public final class XLDocumentPackage {
    public convenience init() {
        try! self.init(opcPackage: OPCPackage())
    }

    public init(opcPackage: OPCPackage) throws {
        var consumedPaths: Set<OPCFilePath> = []

        let contentTypes = try Self.readFile(
            from: opcPackage,
            at: OPCContentTypesFile.path(),
            default: OPCContentTypesFile(),
            read: OPCContentTypesFile.init(xmlDocument:),
            consumedPaths: &consumedPaths
        )

        let packageRels = try Self.readFile(
            from: opcPackage,
            at: try OPCRelsFile.path(for: .packageRoot),
            default: OPCRelsFile(),
            read: OPCRelsFile.init(xmlDocument:),
            consumedPaths: &consumedPaths
        )

        let workbookPath = try XLWorkbookFile.path(in: packageRels.file)
        let workbook = try Self.readFile(
            from: opcPackage,
            at: workbookPath,
            default: XLWorkbookFile(),
            read: XLWorkbookFile.init(xmlDocument:),
            consumedPaths: &consumedPaths
        )

        let workbookRels = try Self.readFile(
            from: opcPackage,
            at: try OPCRelsFile.path(for: workbook.path),
            default: OPCRelsFile(),
            read: OPCRelsFile.init(xmlDocument:),
            consumedPaths: &consumedPaths
        )

        let sharedStrings = try Self.readFile(
            from: opcPackage,
            at: try XLSharedStringsFile.path(workbookPath: workbook.path, workbookRels: workbookRels.file),
            default: XLSharedStringsFile(),
            read: XLSharedStringsFile.init(xmlDocument:),
            consumedPaths: &consumedPaths
        )
        let stylesPath = try XLStylesFile.path(workbookPath: workbook.path, workbookRels: workbookRels.file)
        var styleStorage = XLStyleStorage()
        let styles = try Self.readFile(
            from: opcPackage,
            at: stylesPath,
            default: XLStylesFile(),
            read: { xmlDocument in
                let decodedStyleStorage = try XLStyleStorage(xmlDocument: xmlDocument)
                styleStorage = decodedStyleStorage
                return try XLStylesFile(
                    xmlDocument: xmlDocument,
                    styleStorage: decodedStyleStorage
                )
            },
            consumedPaths: &consumedPaths
        )

        workbook.file.worksheetByID = try Self.worksheets(
            in: opcPackage,
            for: workbook.file.sheets,
            workbookPath: workbook.path,
            workbookRels: workbookRels.file,
            sharedStrings: sharedStrings.file,
            styleStorage: styleStorage,
            consumedPaths: &consumedPaths
        )

        self.contentTypes = contentTypes
        self.packageRels = packageRels
        self.workbook = workbook
        self.workbookRels = workbookRels
        self.sharedStrings = sharedStrings
        self.styles = styles
        self.opaqueFiles = Self.opaqueFiles(in: opcPackage, excluding: consumedPaths)

        if opcPackage.data(at: workbookPath) == nil {
            _ = try self.workbook.file.appendWorksheet(
                name: "Sheet1",
                workbookPath: self.workbook.path,
                workbookRels: &self.workbookRels.file
            )
        }
    }

    public var contentTypes: OPCPathWithFile<OPCContentTypesFile>
    public var packageRels: OPCPathWithFile<OPCRelsFile>
    public var workbook: OPCPathWithFile<XLWorkbookFile>
    public var workbookRels: OPCPathWithFile<OPCRelsFile>
    public var sharedStrings: OPCPathWithFile<XLSharedStringsFile>
    public var styles: OPCPathWithFile<XLStylesFile>
    public var opaqueFiles: [OPCOpaquePathWithFile]

    func makeOPCPackage() throws -> OPCPackage {
        packageRels.file.ensureRelationship(
            type: XMLNamespaceURI.officeDocument.string,
            target: workbook.path.relationshipTarget(relativeTo: .packageRoot)
        )
        let workbookItems = try workbook.file.packageItems(
            workbookPath: workbook.path,
            workbookRels: &workbookRels.file
        )

        sharedStrings.file.records = XLSharedStringRecordsStorage()
        workbook.file.collectSharedStrings(sharedStrings: sharedStrings.file)

        var styleStorage = XLStyleStorage()
        styleStorage.resetCollectableStyleElements(cellStyles: &styles.file.cellStyles)

        try workbook.file.collectStyle(styleStorage: &styleStorage)

        workbookRels.file.ensureRelationship(
            type: XMLNamespaceURI.sharedStrings.string,
            target: sharedStrings.path.relationshipTarget(relativeTo: workbook.path)
        )
        workbookRels.file.ensureRelationship(
            type: XMLNamespaceURI.styles.string,
            target: styles.path.relationshipTarget(relativeTo: workbook.path)
        )

        var package = OPCPackage()
        for opaqueFile in opaqueFiles {
            try package.insertFile(data: opaqueFile.file.data(), at: opaqueFile.path)
        }
        try package.insertXMLFile(pathWithFile: packageRels) { file in
            file.xmlDocument()
        }
        try package.insertXMLFile(pathWithFile: workbook) { file in
            try file.xmlDocument()
        }
        try package.insertXMLFile(pathWithFile: workbookRels) { file in
            file.xmlDocument()
        }
        for file in workbookItems.files {
            if !Self.containsOpaqueFile(at: file.path, in: opaqueFiles) {
                try package.insertXMLFile(pathWithFile: file) { file in
                    try file.xmlDocument(
                        sharedStrings: sharedStrings.file,
                        styleStorage: styleStorage
                    )
                }
            }
        }
        try package.insertXMLFile(pathWithFile: sharedStrings) { file in
            try file.xmlDocument()
        }
        try package.insertXMLFile(pathWithFile: styles) { file in
            try file.xmlDocument(styleStorage: styleStorage)
        }
        Self.registerRequiredContentTypes(
            in: &contentTypes.file,
            workbookPath: workbook.path,
            workbookContentTypeOverrides: workbookItems.contentTypeOverrides,
            sharedStringsPath: sharedStrings.path,
            stylesPath: styles.path,
            stylesContentType: OPCContentTypes.styles
        )
        try package.insertXMLFile(pathWithFile: contentTypes) { file in
            file.xmlDocument()
        }

        return package
    }

    public func clone() -> XLDocumentPackage {
        XLDocumentPackage(
            contentTypes: contentTypes,
            packageRels: packageRels,
            workbook: workbook.clone { $0.clone() },
            workbookRels: workbookRels,
            sharedStrings: sharedStrings.clone { $0.clone() },
            styles: styles.clone { $0.clone() },
            opaqueFiles: opaqueFiles
        )
    }

    private static func readFile<File>(
        from package: OPCPackage,
        at path: OPCFilePath,
        default defaultFile: @autoclosure () -> File,
        read: (XMLDocument) throws -> File,
        consumedPaths: inout Set<OPCFilePath>
    ) throws -> OPCPathWithFile<File> {
        guard let data = package.data(at: path) else {
            return OPCPathWithFile(path: path, file: defaultFile())
        }

        consumedPaths.insert(path)
        return try OPCPathWithFile(
            path: path,
            file: read(XMLDocument(data: data))
        )
    }

    private static func opaqueFiles(
        in package: OPCPackage,
        excluding consumedPaths: Set<OPCFilePath>
    ) -> [OPCOpaquePathWithFile] {
        package.allFilePaths().compactMap { path in
            guard !consumedPaths.contains(path) else {
                return nil
            }
            guard let data = package.data(at: path) else {
                return nil
            }
            return OPCPathWithFile(path: path, file: OPCOpaqueFile(data: data))
        }
    }

    private static func worksheets(
        in package: OPCPackage,
        for sheets: [XLWorkbookFileSheet],
        workbookPath: OPCFilePath,
        workbookRels: OPCRelsFile,
        sharedStrings: XLSharedStringsFile,
        styleStorage: XLStyleStorage,
        consumedPaths: inout Set<OPCFilePath>
    ) throws -> [Int: OPCPathWithFile<XLWorksheetFile>] {
        var worksheets: [Int: OPCPathWithFile<XLWorksheetFile>] = [:]
        for sheet in sheets {
            guard let relationship = workbookRels.relationships.first(where: { $0.id == sheet.relationshipID }),
                  relationship.type == XMLNamespaceURI.worksheet.string
            else {
                continue
            }
            let path = try OPCFilePath(string: relationship.target).resolved(relativeTo: workbookPath)
            let worksheet = try Self.readWorksheetFile(
                from: package,
                at: path,
                sharedStrings: sharedStrings,
                styleStorage: styleStorage,
                default: XLWorksheetFile(),
                consumedPaths: &consumedPaths
            )
            worksheets[sheet.sheetID] = worksheet
        }
        return worksheets
    }

    private static func readWorksheetFile(
        from package: OPCPackage,
        at path: OPCFilePath,
        sharedStrings: XLSharedStringsFile,
        styleStorage: XLStyleStorage,
        default defaultFile: @autoclosure () -> XLWorksheetFile,
        consumedPaths: inout Set<OPCFilePath>
    ) throws -> OPCPathWithFile<XLWorksheetFile> {
        guard let data = package.data(at: path) else {
            return OPCPathWithFile(path: path, file: defaultFile())
        }

        consumedPaths.insert(path)
        return try OPCPathWithFile(
            path: path,
            file: XLWorksheetFile(
                xmlDocument: XMLDocument(data: data),
                sharedStrings: sharedStrings,
                styleStorage: styleStorage
            )
        )
    }

    private static func containsOpaqueFile(
        at path: OPCFilePath,
        in opaqueFiles: [OPCOpaquePathWithFile]
    ) -> Bool {
        opaqueFiles.contains { $0.path == path }
    }

    private static func registerRequiredContentTypes(
        in contentTypes: inout OPCContentTypesFile,
        workbookPath: OPCFilePath,
        workbookContentTypeOverrides: [OPCFilePath: String],
        sharedStringsPath: OPCFilePath,
        stylesPath: OPCFilePath,
        stylesContentType: String?
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
        contentTypes.ensureOverride(
            partName: stylesPath,
            contentType: stylesContentType
        )
    }

}
