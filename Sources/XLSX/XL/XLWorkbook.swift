import Foundation

public struct XLWorkbook: OPCXMLFile {
    struct PackageItems {
        var files: [OPCFileWithPath<XLWorksheet>]
        var contentTypeOverrides: [OPCFilePath: String]
    }

    public init() {
        self.sheets = [Self.defaultSheet]
        self.worksheets = [:]
        self.original = nil
    }

    public init(
        sheets: [XLWorkbookSheet],
        worksheets: [Int: OPCFileWithPath<XLWorksheet>] = [:]
    ) {
        self.sheets = sheets
        self.worksheets = worksheets
        self.original = nil
    }

    public init(xmlDocument: XMLDocument) throws {
        self.sheets = xmlDocument.workbookSheets()
        self.worksheets = [:]
        self.original = xmlDocument
    }

    public var sheets: [XLWorkbookSheet]
    public var worksheets: [Int: OPCFileWithPath<XLWorksheet>]
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

extension XLWorkbook {
    mutating func packageItems(
        workbookPath: OPCFilePath,
        workbookRels: inout OPCRelsFile
    ) throws -> PackageItems {
        var files: [OPCFileWithPath<XLWorksheet>] = []
        var contentTypeOverrides: [OPCFilePath: String] = [:]

        for sheet in sheets {
            let file = try worksheetFile(for: sheet, workbookPath: workbookPath)
            workbookRels.ensureRelationship(
                id: sheet.relationshipID,
                type: XMLNamespaceURI.worksheet.string,
                target: file.path.relationshipTarget(relativeTo: workbookPath)
            )
            worksheets[sheet.sheetID] = file
            files.append(file)
            contentTypeOverrides[file.path] = OPCContentTypes.worksheet
        }

        return PackageItems(
            files: files,
            contentTypeOverrides: contentTypeOverrides
        )
    }

    private func worksheetFile(
        for sheet: XLWorkbookSheet,
        workbookPath: OPCFilePath
    ) throws -> OPCFileWithPath<XLWorksheet> {
        if let existing = worksheets[sheet.sheetID] {
            return existing
        }

        return OPCFileWithPath(
            path: try defaultWorksheetPath(for: sheet, workbookPath: workbookPath),
            file: XLWorksheet()
        )
    }

    private func defaultWorksheetPath(
        for sheet: XLWorkbookSheet,
        workbookPath: OPCFilePath
    ) throws -> OPCFilePath {
        try OPCFilePath(string: "worksheets/sheet\(sheet.sheetID).xml").resolved(relativeTo: workbookPath)
    }
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
