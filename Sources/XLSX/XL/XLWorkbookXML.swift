import Foundation

enum XLWorkbookXML {
    static func firstSheetRelationshipID(in document: XMLDocument) -> String? {
        guard let workbookElement = document.element(name: "workbook"),
              let sheetsElement = workbookElement.elements(name: "sheets").first,
              let sheetElement = sheetsElement.elements(name: "sheet").first
        else {
            return nil
        }
        return sheetElement.attribute("r:id")
    }
}
