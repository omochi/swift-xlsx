import MemberwiseInit

@MemberwiseInit(.public)
public struct XLWorkbook {
    public var package: XLDocumentPackage

    public var worksheets: [XLWorksheet] {
        package.workbook.file.sheets.map { sheet in
            XLWorksheet(
                package: package,
                sheetID: sheet.sheetID,
                file: worksheetFile(for: sheet)
            )
        }
    }

    private func worksheetFile(for sheet: XLWorkbookFileSheet) -> XLWorksheetFile {
        if let existing = package.workbook.file.worksheetFromID[sheet.sheetID] {
            return existing.file
        }

        let file = XLWorksheetFile()
        package.workbook.file.worksheetFromID[sheet.sheetID] = OPCFileWithPath(
            path: defaultWorksheetPath(for: sheet),
            file: file
        )
        return file
    }

    private func defaultWorksheetPath(for sheet: XLWorkbookFileSheet) -> OPCFilePath {
        try! OPCFilePath(string: "worksheets/sheet\(sheet.sheetID).xml")
            .resolved(relativeTo: package.workbook.path)
    }
}
