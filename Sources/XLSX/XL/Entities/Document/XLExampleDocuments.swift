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

    public static func dataValidationDocument() throws -> XLDocument {
        let document = XLDocument()
        let worksheet = try document.workbook.worksheets.first ?? document.workbook.appendWorksheet(name: "Sheet1")
        worksheet.cell(row: 1, column: 1).value = .string("Apple")
        worksheet.cell(row: 2, column: 1).value = .string("Banana")
        worksheet.cell(row: 3, column: 1).value = .string("Cherry")
        worksheet.cell(row: 1, column: 2).value = .string("select↓")
        worksheet.dataValidation = XLDataValidations(
            validations: [
                XLDataValidation(
                    address: XLCellRangeAddressList([
                        XLCellRangeAddress(
                            start: XLCellAddress(row: 2, column: 2),
                            end: XLCellAddress(row: 2, column: 2)
                        ),
                    ]),
                    validationType: .list,
                    formula1: "$A$1:$A$3"
                ),
            ]
        )
        return document
    }

    public static func columnDocument() throws -> XLDocument {
        let document = XLDocument()
        let worksheet = try document.workbook.worksheets.first ?? document.workbook.appendWorksheet(name: "Sheet1")
        let examples: [(column: Int, width: Double)] = [
            (1, 10),
            (2, 20),
            (3, 30),
        ]

        for example in examples {
            worksheet.column(example.column).width = example.width
            worksheet.cell(row: 1, column: example.column).value = .string("width=\(Int(example.width))")
        }

        return document
    }

    public static func formulaDocument() throws -> XLDocument {
        let document = XLDocument()
        let worksheet = try document.workbook.worksheets.first ?? document.workbook.appendWorksheet(name: "Sheet1")
        worksheet.cell(row: 1, column: 2).value = .number(10)
        worksheet.cell(row: 2, column: 2).value = .number(20)
        worksheet.cell(row: 3, column: 2).value = .number(30)
        worksheet.cell(row: 4, column: 1).value = .string("total→")

        let totalCell = worksheet.cell(row: 4, column: 2)
        totalCell.value = .number(60)
        totalCell.formula = .regular("SUM(B1:B3)")

        return document
    }

    public static func worksheetsDocument() throws -> XLDocument {
        let document = XLDocument()
        let worksheet1 = try document.workbook.worksheets.first ?? document.workbook.appendWorksheet(name: "シート1")
        worksheet1.name = "シート1"
        worksheet1.cell(row: 1, column: 1).value = .string("シート1")

        let worksheet2 = try document.workbook.appendWorksheet(name: "シート2")
        worksheet2.cell(row: 1, column: 1).value = .string("シート2")

        let worksheet3 = try document.workbook.appendWorksheet(name: "シート3")
        worksheet3.cell(row: 1, column: 1).value = .string("シート3")

        return document
    }

    public static func styleDocument() throws -> XLDocument {
        let document = XLDocument()
        let worksheet = try document.workbook.worksheets.first ?? document.workbook.appendWorksheet(name: "Sheet1")
        writeNumberFormatExamples(to: worksheet)
        writeFontExamples(to: worksheet)
        writeFillExamples(to: worksheet)
        writeBorderExamples(to: worksheet)
        return document
    }

    private static func writeNumberFormatExamples(to worksheet: XLWorksheet) {
        let examples: [(id: Int, format: String, value: Double)] = [
            (49, "@", 12345),
            (14, "mm-dd-yy", 45825),
            (22, "m/d/yy h:mm", 45825.5),
            (10, "0.00%", 0.125),
            (3, "#,##0", 1234567),
            (46, "[h]:mm:ss", 27.5),
        ]

        for (index, example) in examples.enumerated() {
            let labelCell = worksheet.cell(row: index + 1, column: 1)
            labelCell.value = .string("builtin \(example.id)")

            let formatCell = worksheet.cell(row: index + 1, column: 2)
            formatCell.value = .string(example.format)

            let valueCell = worksheet.cell(row: index + 1, column: 3)
            valueCell.value = .number(example.value)
            valueCell.format = XLCellFormat(numberFormat: .builtin(id: example.id))
        }

        let customFormat = #"yyyy"ねん" m"がつ" d"にち""#
        let customRow = examples.count + 2
        worksheet.cell(row: customRow, column: 1).value = .string("custom")
        worksheet.cell(row: customRow, column: 2).value = .string(customFormat)

        let valueCell = worksheet.cell(row: customRow, column: 3)
        valueCell.value = .number(45825)
        valueCell.format = XLCellFormat(numberFormat: .format(customFormat))
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
            let cell = worksheet.cell(row: index + 1, column: 5)
            cell.value = .string(example.0)
            cell.format = XLCellFormat(font: example.1)
        }
    }

    private static func writeFillExamples(to worksheet: XLWorksheet) {
        let cell = worksheet.cell(row: 2, column: 7)
        cell.value = .string("red")
        cell.format = XLCellFormat(fill: .pattern(XLFill.Pattern(
            patternType: "solid",
            foregroundColor: .rgb("FFFF0000"),
            backgroundColor: .indexed(64)
        )))
    }

    private static func writeBorderExamples(to worksheet: XLWorksheet) {
        let line = XLBorder.Line(style: .thin)
        let examples: [(String, XLBorder)] = [
            ("start", XLBorder(start: line)),
            ("end", XLBorder(end: line)),
            ("left", XLBorder(left: line)),
            ("right", XLBorder(right: line)),
            ("top", XLBorder(top: line)),
            ("bottom", XLBorder(bottom: line)),
            ("diagonal up", XLBorder(diagonal: XLBorder.Diagonal(directions: .up, line: line))),
            ("diagonal down", XLBorder(diagonal: XLBorder.Diagonal(directions: .down, line: line))),
        ]

        for (index, example) in examples.enumerated() {
            let cell = worksheet.cell(row: (index + 1) * 2, column: 9)
            cell.value = .string(example.0)
            cell.format = XLCellFormat(border: example.1)
        }
    }
}
