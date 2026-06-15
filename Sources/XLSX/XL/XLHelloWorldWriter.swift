import Foundation

enum XLHelloWorldWriter {
    static func package(for document: inout XLDocument) throws -> OPCPackage {
        let packageRelationship = document.packageRels.ensureRelationship(
            type: XLXMLURIs.officeDocument,
            preferredTarget: document.workbookPath.description.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        )
        document.workbookPath = try OPCFilePath(string: packageRelationship.target).resolved(relativeTo: OPCFilePath(string: "/"))

        let sheetRelationshipID = document.workbook.firstSheetRelationshipID() ?? "rId1"

        let worksheetRelationship = document.workbookRels.ensureRelationship(
            id: sheetRelationshipID,
            type: XLXMLURIs.worksheet,
            target: "worksheets/sheet1.xml"
        )
        let sharedStringsRelationship = document.workbookRels.ensureRelationship(
            type: XLXMLURIs.sharedStrings,
            preferredTarget: "sharedStrings.xml"
        )
        let worksheetPath = try OPCFilePath(string: worksheetRelationship.target).resolved(relativeTo: document.workbookPath)
        let sharedStringsPath = try OPCFilePath(string: sharedStringsRelationship.target).resolved(relativeTo: document.workbookPath)

        var package = OPCPackage()
        for opaqueFile in document.opaqueFiles {
            try package.insertFile(data: opaqueFile.data, at: opaqueFile.path)
        }
        try package.insertFile(
            data: document.packageRels.data(),
            at: try OPCRelsFile.path(for: OPCFilePath(string: "/"))
        )
        try package.insertFile(data: document.workbook.data(), at: document.workbookPath)
        try package.insertFile(
            data: document.workbookRels.data(),
            at: try OPCRelsFile.path(for: document.workbookPath)
        )
        if !document.hasOpaqueFile(at: worksheetPath) {
            try package.insertFile(
                data: Data(worksheetXML.utf8),
                at: worksheetPath
            )
        }
        if !document.hasOpaqueFile(at: sharedStringsPath) {
            try package.insertFile(
                data: Data(sharedStringsXML.utf8),
                at: sharedStringsPath
            )
        }
        ensureContentTypes(
            in: &document.contentTypes,
            workbookPath: document.workbookPath,
            worksheetPath: worksheetPath,
            sharedStringsPath: sharedStringsPath
        )
        try package.insertFile(data: document.contentTypes.data(), at: OPCFilePath(string: "/[Content_Types].xml"))

        return package
    }

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

    private static func ensureContentTypes(
        in contentTypes: inout OPCContentTypesFile,
        workbookPath: OPCFilePath,
        worksheetPath: OPCFilePath,
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
        contentTypes.ensureOverride(
            partName: worksheetPath,
            contentType: OPCContentTypes.worksheet
        )
        contentTypes.ensureOverride(
            partName: sharedStringsPath,
            contentType: OPCContentTypes.sharedStrings
        )
    }
}

private extension XLDocument {
    func hasOpaqueFile(at path: OPCFilePath) -> Bool {
        opaqueFiles.contains { $0.path == path }
    }
}
