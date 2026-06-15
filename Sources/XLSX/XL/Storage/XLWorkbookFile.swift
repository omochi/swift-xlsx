import Foundation

public struct XLWorkbookFile: OPCXMLFile {
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
        self.sheets = [Self.defaultSheet]
        self.worksheetFromID = [
            Self.defaultSheet.sheetID: OPCFileWithPath(
                path: Self.defaultWorksheetPath,
                file: XLWorksheetFile()
            )
        ]
        self.original = nil
    }

    public init(sheets: [XLWorkbookFileSheet]) {
        self.init(sheets: sheets, worksheetFromID: [:])
    }

    public init(
        sheets: [XLWorkbookFileSheet],
        worksheetFromID: [Int: OPCFileWithPath<XLWorksheetFile>]
    ) {
        self.sheets = sheets
        self.worksheetFromID = worksheetFromID
        self.original = nil
    }

    public init(xmlDocument: XMLDocument) throws {
        self.sheets = Self.workbookSheets(in: xmlDocument)
        self.worksheetFromID = [:]
        self.original = xmlDocument
    }

    public var sheets: [XLWorkbookFileSheet]
    public var worksheetFromID: [Int: OPCFileWithPath<XLWorksheetFile>]
    public var original: XMLDocument?

    private static let defaultSheet = XLWorkbookFileSheet(
        name: "Sheet1",
        sheetID: 1,
        relationshipID: "rId1"
    )
    private static let defaultWorksheetPath = try! OPCFilePath(string: "/xl/worksheets/sheet1.xml")

    public func xmlDocument() throws -> XMLDocument {
        let document = original?.clone() ?? XMLDocument()
        try writeWorkbook(to: document)
        return document
    }

    mutating func appendWorksheet(
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
        worksheetFromID[sheet.sheetID] = file
        workbookRels.ensureRelationship(
            id: sheet.relationshipID,
            type: XMLNamespaceURI.worksheet.string,
            target: file.path.relationshipTarget(relativeTo: workbookPath)
        )

        return AddedWorksheet(sheet: sheet, file: file)
    }

    mutating func removeWorksheet(sheetID: Int) -> RemovedWorksheet? {
        guard let index = sheets.firstIndex(where: { $0.sheetID == sheetID }) else {
            return nil
        }

        let sheet = sheets.remove(at: index)
        let file = worksheetFromID.removeValue(forKey: sheetID)
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

    mutating func packageItems(
        workbookPath: OPCFilePath,
        workbookRels: inout OPCRelsFile
    ) throws -> PackageItems {
        var files: [OPCFileWithPath<XLWorksheetFile>] = []
        var contentTypeOverrides: [OPCFilePath: String] = [:]

        for sheet in sheets {
            if worksheetFromID[sheet.sheetID] == nil,
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
            worksheetFromID[sheet.sheetID] = file
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
        if let existing = worksheetFromID[sheet.sheetID] {
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
