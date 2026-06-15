import Foundation

public struct XLWorkbook: OPCXMLFile {
    public init() {
        self.sheets = [Self.defaultSheet]
        self.original = nil
    }

    public init(sheets: [XLWorkbookSheet]) {
        self.sheets = sheets
        self.original = nil
    }

    public init(xmlDocument: XMLDocument) throws {
        self.sheets = xmlDocument.workbookSheets()
        self.original = xmlDocument
    }

    public var sheets: [XLWorkbookSheet]
    public var original: XMLDocument?

    public func firstSheetRelationshipID() -> String? {
        sheets.first?.relationshipID
    }

    public func xmlDocument() throws -> XMLDocument {
        let document = original?.clone() ?? XMLDocument()
        try ensureWorkbook(in: document)
        return document
    }

    private func ensureWorkbook(in document: XMLDocument) throws {
        let workbookElement = workbookElement(in: document)
        workbookElement.ensureNamespace(uri: .spreadsheet)
        workbookElement.ensureNamespaceURI(prefix: "r", uri: .officeRelationships)

        let sheetsElement = sheetsElement(in: workbookElement)
        for sheet in sheets {
            try sheet.ensureElement(in: sheetsElement)
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

    private static let defaultSheet = XLWorkbookSheet(
        name: "Sheet1",
        sheetID: 1,
        relationshipID: "rId1"
    )
}

private extension XMLDocument {
    func workbookSheets() -> [XLWorkbookSheet] {
        guard let workbookElement = element(name: "workbook"),
              let sheetsElement = workbookElement.elements(name: "sheets").first
        else {
            return []
        }

        return sheetsElement.elements(name: "sheet").compactMap(XLWorkbookSheet.init(element:))
    }
}
