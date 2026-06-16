import MemberwiseInit
import Foundation

@MemberwiseInit(.public)
public final class XLDocumentPackage {
    public convenience init() {
        try! self.init(opcPackage: OPCPackage())
    }

    init(opcPackage: OPCPackage) throws {
        var consumedPaths: Set<OPCFilePath> = []

        let contentTypes = try Self.readFile(
            OPCContentTypesFile.self,
            from: opcPackage,
            at: OPCContentTypesFile.path(),
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

        let workbookPath = try XLWorkbookFile.path(in: packageRels.file)
        let workbook = try Self.readFile(
            XLWorkbookFile.self,
            from: opcPackage,
            at: workbookPath,
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

        let sharedStrings = try Self.readFile(
            XLSharedStringsFile.self,
            from: opcPackage,
            at: try XLSharedStringsFile.path(workbookPath: workbook.path, workbookRels: workbookRels.file),
            default: XLSharedStringsFile(),
            consumedPaths: &consumedPaths
        )
        let styles = try Self.readFile(
            XLStylesFile.self,
            from: opcPackage,
            at: try XLStylesFile.path(workbookPath: workbook.path, workbookRels: workbookRels.file),
            default: XLStylesFile(),
            consumedPaths: &consumedPaths
        )

        workbook.file.worksheetByID = try Self.worksheets(
            in: opcPackage,
            for: workbook.file.sheets,
            workbookPath: workbook.path,
            workbookRels: workbookRels.file,
            sharedStrings: sharedStrings.file,
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
        var contentTypes = contentTypes
        var packageRels = packageRels
        let workbook = workbook
        var workbookRels = workbookRels
        let sharedStrings = sharedStrings
        let styles = styles
        let opaqueFiles = opaqueFiles
        let writesStyles = styles.file.original != nil || !styles.file.isEmpty

        packageRels.file.ensureRelationship(
            type: XMLNamespaceURI.officeDocument.string,
            target: workbook.path.relationshipTarget(relativeTo: .packageRoot)
        )
        let workbookItems = try workbook.file.packageItems(
            workbookPath: workbook.path,
            workbookRels: &workbookRels.file
        )
        let sharedStringPlan = XLSharedStringWritePlan(
            sharedStrings: sharedStrings.file,
            workbook: workbook.file
        )
        sharedStrings.file.apply(sharedStringPlan)
        workbookRels.file.ensureRelationship(
            type: XMLNamespaceURI.sharedStrings.string,
            target: sharedStrings.path.relationshipTarget(relativeTo: workbook.path)
        )
        workbookRels.file.ensureRelationship(
            type: XMLNamespaceURI.styles.string,
            target: writesStyles ? styles.path.relationshipTarget(relativeTo: workbook.path) : nil
        )

        var package = OPCPackage()
        for opaqueFile in opaqueFiles {
            try package.insertFile(opaqueFile)
        }
        try package.insertFile(packageRels)
        try package.insertFile(workbook)
        try package.insertFile(workbookRels)
        for file in workbookItems.files {
            if !Self.containsOpaqueFile(at: file.path, in: opaqueFiles) {
                try package.insertFile(
                    data: try file.file.xmlDocument(sharedStrings: sharedStringPlan).data(),
                    at: file.path
                )
            }
        }
        try package.insertFile(sharedStrings)
        if writesStyles {
            try package.insertFile(styles)
        }
        Self.registerRequiredContentTypes(
            in: &contentTypes.file,
            workbookPath: workbook.path,
            workbookContentTypeOverrides: workbookItems.contentTypeOverrides,
            sharedStringsPath: sharedStrings.path,
            stylesPath: styles.path,
            stylesContentType: writesStyles ? OPCContentTypes.styles : nil
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
    ) throws -> OPCPathWithFile<File> {
        guard let pathWithFile = try package.fileWithPath(type, at: path) else {
            return OPCPathWithFile(path: path, file: defaultFile())
        }

        consumedPaths.insert(path)
        return pathWithFile
    }

    private static func opaqueFiles(
        in package: OPCPackage,
        excluding consumedPaths: Set<OPCFilePath>
    ) -> [OPCOpaquePathWithFile] {
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
        sharedStrings: XLSharedStringsFile,
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
            let worksheet = try Self.readFile(
                XLWorksheetFile.self,
                from: package,
                at: path,
                default: XLWorksheetFile(),
                consumedPaths: &consumedPaths
            )
            worksheet.file.resolveSharedStrings(sharedStrings)
            worksheets[sheet.sheetID] = worksheet
        }
        return worksheets
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
