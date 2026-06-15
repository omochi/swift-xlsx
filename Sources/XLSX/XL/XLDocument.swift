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
            at: try OPCRelsFile.path(for: OPCFilePath(string: "/")),
            default: OPCRelsFile(),
            consumedPaths: &consumedPaths
        )

        let workbook = try package.fileWithPath(
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

    private static let worksheetXML = """
        <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
        <worksheet xmlns="\(XLXMLURIs.spreadsheet)">
          <sheetData>
            <row r="1">
              <c r="A1" t="s">
                <v>0</v>
              </c>
            </row>
          </sheetData>
        </worksheet>
        """

    private static let sharedStringsXML = """
        <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
        <sst xmlns="\(XLXMLURIs.spreadsheet)" count="1" uniqueCount="1">
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
        let workbook = workbook
        var workbookRels = workbookRels
        let opaqueFiles = opaqueFiles

        packageRels.file.ensureRelationship(
            type: XLXMLURIs.officeDocument,
            target: workbook.path.description.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        )

        let sheetRelationshipID = workbook.file.firstSheetRelationshipID() ?? "rId1"

        let worksheetRelationship = workbookRels.file.ensureRelationship(
            id: sheetRelationshipID,
            type: XLXMLURIs.worksheet,
            target: "worksheets/sheet1.xml"
        )
        let sharedStringsRelationship = workbookRels.file.ensureRelationship(
            type: XLXMLURIs.sharedStrings,
            target: "sharedStrings.xml"
        )
        let worksheetPath = try OPCFilePath(string: worksheetRelationship.target).resolved(relativeTo: workbook.path)
        let sharedStringsPath = try OPCFilePath(string: sharedStringsRelationship.target).resolved(relativeTo: workbook.path)

        var package = OPCPackage()
        for opaqueFile in opaqueFiles {
            try package.insertFile(opaqueFile)
        }
        try package.insertFile(packageRels)
        try package.insertFile(workbook)
        try package.insertFile(workbookRels)
        if !opaqueFiles.contains(path: worksheetPath) {
            try package.insertFile(
                data: Data(Self.worksheetXML.utf8),
                at: worksheetPath
            )
        }
        if !opaqueFiles.contains(path: sharedStringsPath) {
            try package.insertFile(
                data: Data(Self.sharedStringsXML.utf8),
                at: sharedStringsPath
            )
        }
        contentTypes.file.ensureRequiredTypes(
            workbookPath: workbook.path,
            worksheetPath: worksheetPath,
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
}

private extension OPCContentTypesFile {
    mutating func ensureRequiredTypes(
        workbookPath: OPCFilePath,
        worksheetPath: OPCFilePath,
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
        ensureOverride(
            partName: worksheetPath,
            contentType: OPCContentTypes.worksheet
        )
        ensureOverride(
            partName: sharedStringsPath,
            contentType: OPCContentTypes.sharedStrings
        )
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
