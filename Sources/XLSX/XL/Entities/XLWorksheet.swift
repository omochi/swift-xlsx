import MemberwiseInit

@MemberwiseInit(.public)
public struct XLWorksheet {
    public var package: XLDocumentPackage
    public var sheetID: Int
    public var file: XLWorksheetFile

    public var name: String {
        get {
            package.workbook.file.sheets[sheetIndex].name
        }
        nonmutating set {
            package.workbook.file.sheets[sheetIndex].name = newValue
        }
    }

    private var sheetIndex: Int {
        guard let index = package.workbook.file.sheets.firstIndex(where: { $0.sheetID == sheetID }) else {
            preconditionFailure("Missing sheet for sheetID \(sheetID)")
        }
        return index
    }
}
