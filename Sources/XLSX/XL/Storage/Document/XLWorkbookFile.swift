import MemberwiseInit
import Foundation

public final class XLWorkbookFile: XMLDocumentConvertible {
    @MemberwiseInit(.public)
    public struct AddedWorksheet {
        public var sheet: XLWorkbookFileSheet
        public var file: OPCPathWithFile<XLWorksheetFile>
    }

    @MemberwiseInit(.public)
    public struct PackageItems {
        public var files: [OPCPathWithFile<XLWorksheetFile>]
        public var contentTypeOverrides: [OPCFilePath: String]
    }

    @MemberwiseInit(.public)
    public struct RemovedWorksheet {
        public var sheet: XLWorkbookFileSheet
        public var file: OPCPathWithFile<XLWorksheetFile>?
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
        worksheetByID: [Int: OPCPathWithFile<XLWorksheetFile>]
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
    public var worksheetByID: [Int: OPCPathWithFile<XLWorksheetFile>]
    public var original: XMLDocument?

    public var worksheetsWithID: [(Int, OPCPathWithFile<XLWorksheetFile>)] {
        sheets.compactMap { sheet in
            guard let worksheet = worksheetByID[sheet.sheetID] else {
                return nil
            }
            return (sheet.sheetID, worksheet)
        }
    }

    public var worksheets: [OPCPathWithFile<XLWorksheetFile>] {
        worksheetsWithID.map(\.1)
    }

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

    public func appendWorksheet(
        name: String,
        workbookPath: OPCFilePath,
        workbookRels: inout OPCRelsFile
    ) throws -> AddedWorksheet {
        let sheet = XLWorkbookFileSheet(
            name: name,
            sheetID: nextSheetID(),
            relationshipID: nextRelationshipID(workbookRels: workbookRels)
        )
        let file = OPCPathWithFile(
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

    public func removeWorksheet(sheetID: Int) -> RemovedWorksheet? {
        guard let index = sheets.firstIndex(where: { $0.sheetID == sheetID }) else {
            return nil
        }

        let sheet = sheets.remove(at: index)
        let file = worksheetByID.removeValue(forKey: sheetID)
        return RemovedWorksheet(sheet: sheet, file: file)
    }

    public func collectSharedStrings(sharedStrings: XLSharedStringsFile) {
        for worksheet in worksheets {
            worksheet.file.collectSharedStrings(sharedStrings: sharedStrings)
        }
    }

    public func collectStyle(styles: XLStylesFile) throws {
        for stage in XLStyleCollectionStage.allCases {
            try collectStyle(stage: stage, styles: styles)
        }
    }

    public func collectStyle(stage: XLStyleCollectionStage, styles: XLStylesFile) throws {
        for worksheet in worksheets {
            try worksheet.file.collectStyle(stage: stage, styles: styles)
        }
    }

    public func clone() -> XLWorkbookFile {
        let file = XLWorkbookFile(
            sheets: sheets,
            worksheetByID: worksheetByID.mapValues { worksheet in
                worksheet.clone { $0.clone() }
            }
        )
        file.original = original
        return file
    }

    private func writeWorkbook(to document: XMLDocument) throws {
        let workbookElement = XMLUtils.ensureRootElement(name: "workbook", in: document)
        workbookElement.ensureNamespace(uri: .spreadsheet)
        workbookElement.ensureNamespaceURI(prefix: "r", uri: .officeRelationships)

        let sheetsElement = XMLUtils.ensureChildElement(name: "sheets", in: workbookElement)
        for sheet in sheets {
            let element = sheetElementForWriting(sheetID: sheet.sheetID, in: sheetsElement)
            try sheet.write(to: element)
        }
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

    public func packageItems(
        workbookPath: OPCFilePath,
        workbookRels: inout OPCRelsFile
    ) throws -> PackageItems {
        var files: [OPCPathWithFile<XLWorksheetFile>] = []
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
    ) throws -> OPCPathWithFile<XLWorksheetFile> {
        if let existing = worksheetByID[sheet.sheetID] {
            return existing
        }

        return OPCPathWithFile(
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
