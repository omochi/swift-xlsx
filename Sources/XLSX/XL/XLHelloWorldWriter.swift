import Foundation

enum XLHelloWorldWriter {
    static func package(for workbook: inout XLWorkbook) throws -> OPCPackage {
        let packageRelationship = workbook.packageRels.ensureRelationship(
            type: XLXMLURIs.officeDocument,
            preferredTarget: workbook.workbookPath.description.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        )
        workbook.workbookPath = try OPCFilePath(string: packageRelationship.target).resolved(relativeTo: OPCFilePath(string: "/"))

        let sheetRelationshipID = workbook.workbook.firstSheetRelationshipID() ?? "rId1"

        let worksheetRelationship = workbook.workbookRels.ensureRelationship(
            id: sheetRelationshipID,
            type: XLXMLURIs.worksheet,
            target: "worksheets/sheet1.xml"
        )
        let sharedStringsRelationship = workbook.workbookRels.ensureRelationship(
            type: XLXMLURIs.sharedStrings,
            preferredTarget: "sharedStrings.xml"
        )
        let worksheetPath = try OPCFilePath(string: worksheetRelationship.target).resolved(relativeTo: workbook.workbookPath)
        let sharedStringsPath = try OPCFilePath(string: sharedStringsRelationship.target).resolved(relativeTo: workbook.workbookPath)

        var package = OPCPackage()
        for opaqueFile in workbook.opaqueFiles {
            try package.insertFile(data: opaqueFile.data, at: opaqueFile.path)
        }
        try package.insertFile(data: workbook.packageRels.data(), at: OPCFilePath(string: "/_rels/.rels"))
        try package.insertFile(data: workbook.workbook.data(), at: workbook.workbookPath)
        try package.insertFile(
            data: workbook.workbookRels.data(),
            at: try OPCRelsFile.path(for: workbook.workbookPath)
        )
        if !workbook.hasOpaqueFile(at: worksheetPath) {
            try package.insertFile(
                data: Data(worksheetXML.utf8),
                at: worksheetPath
            )
        }
        if !workbook.hasOpaqueFile(at: sharedStringsPath) {
            try package.insertFile(
                data: Data(sharedStringsXML.utf8),
                at: sharedStringsPath
            )
        }
        ensureContentTypes(
            in: &workbook.contentTypes,
            workbookPath: workbook.workbookPath,
            worksheetPath: worksheetPath,
            sharedStringsPath: sharedStringsPath
        )
        try package.insertFile(data: workbook.contentTypes.data(), at: OPCFilePath(string: "/[Content_Types].xml"))

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

private extension XLWorkbook {
    func hasOpaqueFile(at path: OPCFilePath) -> Bool {
        opaqueFiles.contains { $0.path == path }
    }
}
