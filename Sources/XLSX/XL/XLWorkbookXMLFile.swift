import Foundation

struct XLWorkbookXMLFile {
    var path: OPCFilePath
    var document: XMLDocument

    init(path: OPCFilePath, data: Data) throws {
        self.path = path
        self.document = try XMLDocumentReader.parse(data)
    }

    static func `default`(path: OPCFilePath) throws -> XLWorkbookXMLFile {
        try XLWorkbookXMLFile(path: path, data: Data(defaultXML.utf8))
    }

    func firstSheetRelationshipID() -> String? {
        XLWorkbookXML.firstSheetRelationshipID(in: document)
    }

    func data() -> Data {
        document.data()
    }

    private static let defaultXML = """
        <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
        <workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main"
          xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">
          <sheets>
            <sheet name="Sheet1" sheetId="1" r:id="rId1"/>
          </sheets>
        </workbook>
        """
}
