import Foundation

struct XLWorkbookFile {
    var path: OPCFilePath
    var document: XMLDocument

    init(path: OPCFilePath, data: Data) throws {
        self.path = path
        self.document = try XMLDocumentReader.parse(data)
    }

    static func `default`(path: OPCFilePath) throws -> XLWorkbookFile {
        try XLWorkbookFile(path: path, data: Data(defaultXML.utf8))
    }

    func firstSheetRelationshipID() -> String? {
        document.firstSheetRelationshipID()
    }

    func data() -> Data {
        document.data()
    }

    private static let defaultXML = """
        <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
        <workbook xmlns="\(XLXMLURIs.spreadsheet)"
          xmlns:r="\(XLXMLURIs.officeRelationships)">
          <sheets>
            <sheet name="Sheet1" sheetId="1" r:id="rId1"/>
          </sheets>
        </workbook>
        """
}

private extension XMLDocument {
    func firstSheetRelationshipID() -> String? {
        guard let workbookElement = element(name: "workbook"),
              let sheetsElement = workbookElement.elements(name: "sheets").first,
              let sheetElement = sheetsElement.elements(name: "sheet").first
        else {
            return nil
        }
        return sheetElement.attribute("r:id")
    }
}
