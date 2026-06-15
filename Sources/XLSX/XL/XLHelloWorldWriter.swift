import Foundation

enum XLHelloWorldWriter {
    static func package(for file: inout XLWorkbookFile) throws -> OPCPackage {
        let packageRelationship = file.packageRels.ensureRelationship(
            type: XLXMLURIs.officeDocument,
            preferredTarget: file.workbookPath.description.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        )
        file.workbookPath = try OPCFilePath(string: packageRelationship.target).resolved(relativeTo: OPCFilePath(string: "/"))

        let sheetRelationshipID = file.workbook.firstSheetRelationshipID() ?? "rId1"

        let worksheetRelationship = file.workbookRels.ensureRelationship(
            id: sheetRelationshipID,
            type: XLXMLURIs.worksheet,
            target: "worksheets/sheet1.xml"
        )
        let sharedStringsRelationship = file.workbookRels.ensureRelationship(
            type: XLXMLURIs.sharedStrings,
            preferredTarget: "sharedStrings.xml"
        )
        let worksheetPath = try OPCFilePath(string: worksheetRelationship.target).resolved(relativeTo: file.workbookPath)
        let sharedStringsPath = try OPCFilePath(string: sharedStringsRelationship.target).resolved(relativeTo: file.workbookPath)

        var package = OPCPackage()
        for opaqueFile in file.opaqueFiles {
            try package.insertFile(data: opaqueFile.data, at: opaqueFile.path)
        }
        try package.insertFile(data: file.packageRels.data(), at: OPCFilePath(string: "/_rels/.rels"))
        try package.insertFile(data: file.workbook.data(), at: file.workbookPath)
        try package.insertFile(
            data: file.workbookRels.data(),
            at: try OPCRelsFile.path(for: file.workbookPath)
        )
        try package.insertFile(
            data: Data(worksheetXML.utf8),
            at: worksheetPath
        )
        try package.insertFile(
            data: Data(sharedStringsXML.utf8),
            at: sharedStringsPath
        )
        ensureContentTypes(
            in: &file.contentTypes,
            workbookPath: file.workbookPath,
            worksheetPath: worksheetPath,
            sharedStringsPath: sharedStringsPath
        )
        try package.insertFile(data: file.contentTypes.data(), at: OPCFilePath(string: "/[Content_Types].xml"))

        return package
    }

    private static let worksheetXML = """
        <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
        <worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">
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
        <sst xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" count="1" uniqueCount="1">
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
            contentType: "application/vnd.openxmlformats-package.relationships+xml"
        )
        contentTypes.ensureDefault(
            extension: "xml",
            contentType: "application/xml"
        )
        contentTypes.ensureOverride(
            partName: workbookPath,
            contentType: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"
        )
        contentTypes.ensureOverride(
            partName: worksheetPath,
            contentType: "application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"
        )
        contentTypes.ensureOverride(
            partName: sharedStringsPath,
            contentType: "application/vnd.openxmlformats-officedocument.spreadsheetml.sharedStrings+xml"
        )
    }
}
