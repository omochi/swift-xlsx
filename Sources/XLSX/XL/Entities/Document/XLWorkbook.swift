import MemberwiseInit

@MemberwiseInit(.public)
public struct XLWorkbook {
    public var package: XLDocumentPackage

    public var worksheets: [XLWorksheet] {
        package.workbook.file.worksheetsWithID.map { sheetID, worksheet in
            return XLWorksheet(
                package: package,
                sheetID: sheetID,
                file: worksheet.file
            )
        }
    }

    @discardableResult
    public func appendWorksheet(name: String) throws -> XLWorksheet {
        let added = try package.workbook.file.appendWorksheet(
            name: name,
            workbookPath: package.workbook.path,
            workbookRels: &package.workbookRels.file
        )

        return XLWorksheet(
            package: package,
            sheetID: added.sheet.sheetID,
            file: added.file.file
        )
    }

    public func removeWorksheet(sheetID: Int) {
        guard let removed = package.workbook.file.removeWorksheet(sheetID: sheetID) else {
            return
        }

        package.workbookRels.file.removeRelationship(id: removed.sheet.relationshipID)
        if let file = removed.file {
            package.contentTypes.file.ensureOverride(partName: file.path, contentType: nil)
        }
    }
}
