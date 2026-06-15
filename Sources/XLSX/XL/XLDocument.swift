import Foundation

public struct XLDocument {
    public init() {
        try! self.init(package: OPCPackage())
    }

    public init(package: OPCPackage) throws {
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

        self.contentTypesPath = contentTypesPath
        self.contentTypes = contentTypes
        self.packageRelsPath = packageRelsPath
        self.packageRels = packageRels
        self.workbookPath = workbookPath
        self.workbook = workbook
        self.workbookRels = workbookRels
        self.opaqueFiles = opaqueFiles
    }

    public var contentTypesPath: OPCFilePath
    public var contentTypes: OPCContentTypesFile
    public var packageRelsPath: OPCFilePath
    public var packageRels: OPCRelsFile
    public var workbookPath: OPCFilePath
    public var workbook: XLWorkbook
    public var workbookRels: OPCRelsFile
    public var opaqueFiles: [OPCOpaqueFile]

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
        let contentTypesPath = contentTypesPath
        var contentTypes = contentTypes
        let packageRelsPath = packageRelsPath
        var packageRels = packageRels
        let workbookPath = workbookPath
        let workbook = workbook
        var workbookRels = workbookRels
        let opaqueFiles = opaqueFiles

        packageRels.ensureRelationship(
            type: XLXMLURIs.officeDocument,
            target: workbookPath.description.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        )

        let sheetRelationshipID = workbook.firstSheetRelationshipID() ?? "rId1"

        let worksheetRelationship = workbookRels.ensureRelationship(
            id: sheetRelationshipID,
            type: XLXMLURIs.worksheet,
            target: "worksheets/sheet1.xml"
        )
        let sharedStringsRelationship = workbookRels.ensureRelationship(
            type: XLXMLURIs.sharedStrings,
            target: "sharedStrings.xml"
        )
        let worksheetPath = try OPCFilePath(string: worksheetRelationship.target).resolved(relativeTo: workbookPath)
        let sharedStringsPath = try OPCFilePath(string: sharedStringsRelationship.target).resolved(relativeTo: workbookPath)

        var package = OPCPackage()
        for opaqueFile in opaqueFiles {
            try package.insertFile(data: opaqueFile.data, at: opaqueFile.path)
        }
        try package.insertFile(
            data: packageRels.data(),
            at: packageRelsPath
        )
        try package.insertFile(data: workbook.data(), at: workbookPath)
        try package.insertFile(
            data: workbookRels.data(),
            at: try OPCRelsFile.path(for: workbookPath)
        )
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
        contentTypes.ensureRequiredTypes(
            workbookPath: workbookPath,
            worksheetPath: worksheetPath,
            sharedStringsPath: sharedStringsPath
        )
        try package.insertFile(data: contentTypes.data(), at: contentTypesPath)

        return package
    }

}

private extension [OPCOpaqueFile] {
    func contains(path: OPCFilePath) -> Bool {
        contains { $0.path == path }
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
