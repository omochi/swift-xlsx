import Foundation

public final class XLWorkbookFile: OPCXMLFile {
    struct AddedWorksheet {
        var sheet: XLWorkbookFileSheet
        var file: OPCFileWithPath<XLWorksheetFile>
    }

    struct PackageItems {
        var files: [OPCFileWithPath<XLWorksheetFile>]
        var contentTypeOverrides: [OPCFilePath: String]
    }

    struct RemovedWorksheet {
        var sheet: XLWorkbookFileSheet
        var file: OPCFileWithPath<XLWorksheetFile>?
    }

    public init() {
        self.sheets = []
        self.worksheetByID = [:]
        self.original = nil
    }

    public convenience init(sheets: [XLWorkbookFileSheet]) {
        self.init(sheets: sheets, worksheetByID: [:])
    }

    public init(
        sheets: [XLWorkbookFileSheet],
        worksheetByID: [Int: OPCFileWithPath<XLWorksheetFile>]
    ) {
        self.sheets = sheets
        self.worksheetByID = worksheetByID
        self.original = nil
    }

    public init(xmlDocument: XMLDocument) throws {
        self.sheets = Self.workbookSheets(in: xmlDocument)
        self.worksheetByID = [:]
        self.original = xmlDocument
    }

    public var sheets: [XLWorkbookFileSheet]
    public var worksheetByID: [Int: OPCFileWithPath<XLWorksheetFile>]
    public var original: XMLDocument?

    public static func path(in packageRels: OPCRelsFile) throws -> OPCFilePath {
        if let relationship = packageRels.relationships.first(where: { $0.type == XMLNamespaceURI.officeDocument.string }) {
            return try OPCFilePath(string: relationship.target).resolved(relativeTo: .packageRoot)
        }
        return try OPCFilePath(string: "/xl/workbook.xml")
    }

    public func xmlDocument() throws -> XMLDocument {
        let document = original?.clone() ?? XMLDocument()
        try writeWorkbook(to: document)
        return document
    }

    func appendWorksheet(
        name: String,
        workbookPath: OPCFilePath,
        workbookRels: inout OPCRelsFile
    ) throws -> AddedWorksheet {
        let sheet = XLWorkbookFileSheet(
            name: name,
            sheetID: nextSheetID(),
            relationshipID: nextRelationshipID(workbookRels: workbookRels)
        )
        let file = OPCFileWithPath(
            path: try defaultWorksheetPath(for: sheet, workbookPath: workbookPath),
            file: XLWorksheetFile()
        )

        sheets.append(sheet)
        worksheetByID[sheet.sheetID] = file
        workbookRels.ensureRelationship(
            id: sheet.relationshipID,
            type: XMLNamespaceURI.worksheet.string,
            target: file.path.relationshipTarget(relativeTo: workbookPath)
        )

        return AddedWorksheet(sheet: sheet, file: file)
    }

    func removeWorksheet(sheetID: Int) -> RemovedWorksheet? {
        guard let index = sheets.firstIndex(where: { $0.sheetID == sheetID }) else {
            return nil
        }

        let sheet = sheets.remove(at: index)
        let file = worksheetByID.removeValue(forKey: sheetID)
        return RemovedWorksheet(sheet: sheet, file: file)
    }

    private func writeWorkbook(to document: XMLDocument) throws {
        let workbookElement = workbookElementForWriting(in: document)
        workbookElement.ensureNamespace(uri: .spreadsheet)
        workbookElement.ensureNamespaceURI(prefix: "r", uri: .officeRelationships)

        let sheetsElement = sheetsElementForWriting(in: workbookElement)
        for sheet in sheets {
            let element = sheetElementForWriting(sheetID: sheet.sheetID, in: sheetsElement)
            try sheet.write(to: element)
        }
    }

    private func workbookElementForWriting(in document: XMLDocument) -> XMLElement {
        if let element = document.element(name: "workbook") {
            return element
        }

        let element = XMLElement(name: XMLName(name: "workbook"))
        document.appendChild(element)
        return element
    }

    private func sheetsElementForWriting(in workbookElement: XMLElement) -> XMLElement {
        if let element = workbookElement.elements(name: "sheets").first {
            return element
        }

        let element = XMLElement(name: XMLName(name: "sheets"))
        workbookElement.appendChild(element)
        return element
    }

    private func sheetElementForWriting(sheetID: Int, in sheetsElement: XMLElement) -> XMLElement {
        if let element = sheetsElement.elements(name: "sheet").first(where: { element in
            XLWorkbookFileSheet(element: element)?.sheetID == sheetID
        }) {
            return element
        }

        let element = XMLElement(name: XMLName(name: "sheet"))
        sheetsElement.appendChild(element)
        return element
    }

    func packageItems(
        workbookPath: OPCFilePath,
        workbookRels: inout OPCRelsFile
    ) throws -> PackageItems {
        var files: [OPCFileWithPath<XLWorksheetFile>] = []
        var contentTypeOverrides: [OPCFilePath: String] = [:]

        for sheet in sheets {
            if worksheetByID[sheet.sheetID] == nil,
               let relationship = workbookRels.relationships.first(where: { $0.id == sheet.relationshipID }),
               relationship.type != XMLNamespaceURI.worksheet.string
            {
                continue
            }

            let file = try worksheetFile(for: sheet, workbookPath: workbookPath)
            workbookRels.ensureRelationship(
                id: sheet.relationshipID,
                type: XMLNamespaceURI.worksheet.string,
                target: file.path.relationshipTarget(relativeTo: workbookPath)
            )
            worksheetByID[sheet.sheetID] = file
            files.append(file)
            contentTypeOverrides[file.path] = OPCContentTypes.worksheet
        }

        return PackageItems(
            files: files,
            contentTypeOverrides: contentTypeOverrides
        )
    }

    private func worksheetFile(
        for sheet: XLWorkbookFileSheet,
        workbookPath: OPCFilePath
    ) throws -> OPCFileWithPath<XLWorksheetFile> {
        if let existing = worksheetByID[sheet.sheetID] {
            return existing
        }

        return OPCFileWithPath(
            path: try defaultWorksheetPath(for: sheet, workbookPath: workbookPath),
            file: XLWorksheetFile()
        )
    }

    private func defaultWorksheetPath(
        for sheet: XLWorkbookFileSheet,
        workbookPath: OPCFilePath
    ) throws -> OPCFilePath {
        try OPCFilePath(string: "worksheets/sheet\(sheet.sheetID).xml").resolved(relativeTo: workbookPath)
    }

    private func nextSheetID() -> Int {
        (sheets.map(\.sheetID).max() ?? 0) + 1
    }

    private func nextRelationshipID(workbookRels: OPCRelsFile) -> String {
        let usedIDs = Set(workbookRels.relationships.map(\.id) + sheets.map(\.relationshipID))
        let maxID = usedIDs.compactMap { id -> Int? in
            guard id.hasPrefix("rId") else {
                return nil
            }
            return Int(id.dropFirst(3))
        }.max() ?? 0

        return "rId\(maxID + 1)"
    }

    private static func workbookSheets(in document: XMLDocument) -> [XLWorkbookFileSheet] {
        guard let workbookElement = document.element(name: "workbook"),
              let sheetsElement = workbookElement.elements(name: "sheets").first
        else {
            return []
        }

        return sheetsElement.elements(name: "sheet").compactMap(XLWorkbookFileSheet.init(element:))
    }
}
