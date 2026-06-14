import Foundation

enum XLWorkbookXML {
    static func firstSheetRelationshipID(in document: XMLDocument) -> String? {
        guard let sheetElement = XMLDocument.firstElement(named: "sheet", in: document) else {
            return nil
        }
        return XMLDocument.attribute("r:id", of: sheetElement, in: document)
    }
}
