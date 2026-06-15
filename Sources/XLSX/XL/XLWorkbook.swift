import Foundation

public struct XLWorkbook: OPCFile {
    public init() {
        self.original = nil
    }

    public init(data: Data) throws {
        self.original = try XMLDocumentReader.parse(data)
    }

    public var original: XMLDocument?

    public func firstSheetRelationshipID() -> String? {
        xmlDocument.firstSheetRelationshipID()
    }

    public func data() -> Data {
        xmlDocument.data()
    }

    private var xmlDocument: XMLDocument {
        let document = original?.clone() ?? XMLDocument()
        ensureWorkbook(in: document)
        return document
    }

    private func ensureWorkbook(in document: XMLDocument) {
        let workbookElement = workbookElement(in: document)
        workbookElement.ensureNamespace(uri: XMLNamespaceURI(XLXMLURIs.spreadsheet))
        workbookElement.ensureNamespace(prefix: "r", uri: XMLNamespaceURI(XLXMLURIs.officeRelationships))

        let sheetsElement = sheetsElement(in: workbookElement)
        if sheetsElement.elements(name: "sheet").isEmpty {
            sheetsElement.appendChild(XMLElement(
                name: XMLName(name: "sheet"),
                attributes: [
                    XMLAttribute(name: XMLName(name: "name"), value: "Sheet1"),
                    XMLAttribute(name: XMLName(name: "sheetId"), value: "1"),
                    XMLAttribute(name: XMLName(prefix: "r", name: "id"), value: "rId1"),
                ]
            ))
        }
    }

    private func workbookElement(in document: XMLDocument) -> XMLElement {
        if let element = document.element(name: "workbook") {
            return element
        }

        let element = XMLElement(name: XMLName(name: "workbook"))
        document.appendChild(element)
        return element
    }

    private func sheetsElement(in workbookElement: XMLElement) -> XMLElement {
        if let element = workbookElement.elements(name: "sheets").first {
            return element
        }

        let element = XMLElement(name: XMLName(name: "sheets"))
        workbookElement.appendChild(element)
        return element
    }
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
