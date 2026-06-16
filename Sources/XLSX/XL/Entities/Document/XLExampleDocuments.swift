public enum XLExampleDocuments {
    public static func defaultDocument() -> XLDocument {
        XLDocument()
    }

    public static func simpleDocument() throws -> XLDocument {
        let document = XLDocument()
        let worksheet = try document.workbook.worksheets.first ?? document.workbook.appendWorksheet(name: "Sheet1")
        worksheet.cell(row: 1, column: 1).value = .string("A")
        worksheet.cell(row: 1, column: 2).value = .string("B")
        worksheet.cell(row: 1, column: 3).value = .string("C")
        return document
    }

    public static func styleDocument() throws -> XLDocument {
        let document = XLDocument()
        let worksheet = try document.workbook.worksheets.first ?? document.workbook.appendWorksheet(name: "Sheet1")
        writeFontExamples(to: worksheet)
        writeFillExamples(to: worksheet)
        return document
    }

    private static func writeFontExamples(to worksheet: XLWorksheet) {
        let examples: [(String, XLFont)] = [
            ("bold", XLFont(bold: true)),
            ("italic", XLFont(italic: true)),
            ("strike", XLFont(strike: true)),
            ("size", XLFont(size: 18)),
            ("name", XLFont(name: "Courier New")),
        ]

        for (index, example) in examples.enumerated() {
            let cell = worksheet.cell(row: index + 1, column: 1)
            cell.value = .string(example.0)
            cell.format = XLCellFormat(font: example.1)
        }
    }

    private static func writeFillExamples(to worksheet: XLWorksheet) {
        let cell = worksheet.cell(row: 2, column: 3)
        cell.value = .string("red")
        cell.format = XLCellFormat(fill: .pattern(XLFill.Pattern(
            patternType: "solid",
            foregroundColor: .rgb("FFFF0000"),
            backgroundColor: .indexed(64)
        )))
    }
}
