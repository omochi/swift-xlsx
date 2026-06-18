import XLSX

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

    public static func exampleDocument() throws -> XLDocument {
        let document = XLDocument()
        let formulaWorksheet = try document.workbook.worksheets.first ?? document.workbook.appendWorksheet(name: "formula")
        formulaWorksheet.name = "formula"
        writeFormulaExamples(to: formulaWorksheet)
        writeColumnExamples(to: try document.workbook.appendWorksheet(name: "column"))
        writeNumberFormatExamples(to: try document.workbook.appendWorksheet(name: "number format"))
        writeFontExamples(to: try document.workbook.appendWorksheet(name: "font"))
        writeFillExamples(to: try document.workbook.appendWorksheet(name: "fill"))
        writeBorderExamples(to: try document.workbook.appendWorksheet(name: "border"))
        writeDataValidationExamples(to: try document.workbook.appendWorksheet(name: "data validation"))
        return document
    }

    private static func writeFormulaExamples(to worksheet: XLWorksheet) {
        worksheet.cell(row: 1, column: 2).value = .number(10)
        worksheet.cell(row: 2, column: 2).value = .number(20)
        worksheet.cell(row: 3, column: 2).value = .number(30)
        worksheet.cell(row: 4, column: 1).value = .string("sum→")

        let totalCell = worksheet.cell(row: 4, column: 2)
        totalCell.value = .number(60)
        totalCell.formula = .regular("SUM(B1:B3)")
    }

    private static func writeColumnExamples(to worksheet: XLWorksheet) {
        let examples: [(column: Int, width: Double)] = [
            (1, 10),
            (2, 20),
            (3, 30),
        ]

        for example in examples {
            worksheet.column(example.column).width = example.width
            worksheet.cell(row: 1, column: example.column).value = .string("width=\(Int(example.width))")
        }
    }

    private static func writeNumberFormatExamples(to worksheet: XLWorksheet) {
        worksheet.column(2).width = 24
        worksheet.column(3).width = 20

        let examples: [(id: Int, symbol: String, numberFormat: XLNumberFormat, value: Double)] = [
            (0, "general", .general, 1234.5),
            (1, "integer", .integer, 1234.5),
            (2, "decimal2", .decimal2, 1234.5),
            (3, "thousandsInteger", .thousandsInteger, 1234567),
            (4, "thousandsDecimal2", .thousandsDecimal2, 1234567.8),
            (9, "percent", .percent, 0.125),
            (10, "percentDecimal2", .percentDecimal2, 0.125),
            (14, "date", .date, 45825),
            (20, "time", .time, 0.5),
            (21, "timeWithSeconds", .timeWithSeconds, 0.5006944444444444),
            (22, "dateTime", .dateTime, 45825.5),
            (46, "elapsedTime", .elapsedTime, 27.5),
            (49, "text", .text, 12345),
        ]

        for (index, example) in examples.enumerated() {
            let labelCell = worksheet.cell(row: index + 1, column: 1)
            labelCell.value = .string("builtin \(example.id)")

            let symbolCell = worksheet.cell(row: index + 1, column: 2)
            symbolCell.value = .string(example.symbol)

            let valueCell = worksheet.cell(row: index + 1, column: 3)
            valueCell.value = .number(example.value)
            valueCell.format = XLCellFormat(numberFormat: example.numberFormat)
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
            ("red", XLFont(color: .rgb("FFFF0000"))),
        ]

        for (index, example) in examples.enumerated() {
            let cell = worksheet.cell(row: index + 1, column: 1)
            cell.value = .string(example.0)
            cell.format = XLCellFormat(font: example.1)
        }
    }

    private static func writeFillExamples(to worksheet: XLWorksheet) {
        let cell = worksheet.cell(row: 1, column: 1)
        cell.value = .string("red")
        cell.format = XLCellFormat(fill: .pattern(XLFill.Pattern(
            patternType: .solid,
            foregroundColor: .rgb("FFFF0000"),
            backgroundColor: .indexed(64)
        )))
    }

    private static func writeBorderExamples(to worksheet: XLWorksheet) {
        let line = XLBorder.Line(style: .thin)
        let mediumLine = XLBorder.Line(style: .medium)
        let examples: [(String, XLBorder)] = [
            ("start", XLBorder(start: line)),
            ("end", XLBorder(end: line)),
            ("left", XLBorder(left: line)),
            ("right", XLBorder(right: line)),
            ("top", XLBorder(top: line)),
            ("bottom", XLBorder(bottom: line)),
            ("diagonal up", XLBorder(diagonal: XLBorder.Diagonal(directions: .up, line: line))),
            ("diagonal down", XLBorder(diagonal: XLBorder.Diagonal(directions: .down, line: line))),
            ("medium", XLBorder(left: mediumLine, right: mediumLine, top: mediumLine, bottom: mediumLine)),
        ]

        for (index, example) in examples.enumerated() {
            let cell = worksheet.cell(row: (index + 1) * 2, column: 2)
            cell.value = .string(example.0)
            cell.format = XLCellFormat(border: example.1)
        }
    }

    private static func writeDataValidationExamples(to worksheet: XLWorksheet) {
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
    }
}
