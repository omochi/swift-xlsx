import MemberwiseInit

@MemberwiseInit(.public)
public struct XLWorkbook {
    public var package: XLDocumentPackage

    public var worksheets: [XLWorksheet] {
        package.workbook.file.sheets.compactMap { sheet in
            guard let file = package.workbook.file.worksheetFromID[sheet.sheetID]?.file else {
                return nil
            }

            return XLWorksheet(
                package: package,
                sheetID: sheet.sheetID,
                file: file
            )
        }
    }
}
