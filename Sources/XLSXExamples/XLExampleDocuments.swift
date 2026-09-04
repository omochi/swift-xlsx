import struct Foundation.Data
import struct Foundation.Date
import XLSX

public enum XLExampleDocuments {
    public static func defaultDocument() -> XLDocument {
        XLDocument()
    }

    public static func simpleDocument() throws -> XLDocument {
        let document = XLDocument()
        let worksheet = try document.workbook.worksheets.first ?? document.workbook.appendWorksheet(name: "Sheet1")
        worksheet.cell(row: 1, column: 1).value = .text("A")
        worksheet.cell(row: 1, column: 2).value = .text("B")
        worksheet.cell(row: 1, column: 3).value = .text("C")
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
        writePasswordProtectionExamples(to: try document.workbook.appendWorksheet(name: "password"))
        writeHiddenSheetExamples(to: try document.workbook.appendWorksheet(name: "hidden"))
        writeCellValueExamples(to: try document.workbook.appendWorksheet(name: "cell value"))
        writeFreezePanesExamples(to: try document.workbook.appendWorksheet(name: "freeze panes"))
        writeCellStyleExamples(
            document: document,
            worksheet: try document.workbook.appendWorksheet(name: "cell style")
        )
        writeVeryHiddenSheetExamples(to: try document.workbook.appendWorksheet(name: "very hidden"))
        return document
    }

    private static func writeFormulaExamples(to worksheet: XLWorksheet) {
        worksheet.column(1).width = 20
        worksheet.column(3).width = 20

        worksheet.cell(row: 1, column: 2).value = .number(10)
        worksheet.cell(row: 2, column: 2).value = .number(20)
        worksheet.cell(row: 3, column: 2).value = .number(30)
        worksheet.cell(row: 4, column: 1).value = .text("regular formula")

        let totalCell = worksheet.cell(row: 4, column: 2)
        totalCell.value = .number(60)
        totalCell.formula = .regular("SUM(B1:B3)")

        for row in 1...3 {
            worksheet.cell(row: row, column: 3).value = .text("shared formula")
        }

        let sharedFormulaCell = worksheet.cell(row: 1, column: 4)
        sharedFormulaCell.value = .number(20)
        sharedFormulaCell.formula = .sharedDefinition(XLSharedFormulaDefinition(
            formula: "B1*2",
            reference: XLCellRangeAddress(
                start: XLCellAddress(row: 1, column: 4),
                last: XLCellAddress(row: 3, column: 4)
            )
        ))

        for row in 2...3 {
            let cell = worksheet.cell(row: row, column: 4)
            cell.value = .number(Double(row * 20))
            cell.formula = .sharedReference(address: sharedFormulaCell.address)
        }

        worksheet.cell(row: 6, column: 1).value = .text("cached string")
        let cachedStringCell = worksheet.cell(row: 6, column: 2)
        cachedStringCell.value = .text("10")
        cachedStringCell.formula = .regular(#"TEXT(B1,"0")"#)
    }

    private static func writeColumnExamples(to worksheet: XLWorksheet) {
        let examples: [(column: Int, width: Double)] = [
            (1, 10),
            (2, 20),
            (3, 30),
        ]

        for example in examples {
            worksheet.column(example.column).width = example.width
            worksheet.cell(row: 1, column: example.column).value = .text("width=\(Int(example.width))")
        }

        let formattedColumn = worksheet.column(4)
        formattedColumn.width = 20
        formattedColumn.format = XLCellFormat(numberFormat: .percent)
        let formattedColumnCell = worksheet.cell(row: 1, column: 4)
        formattedColumnCell.value = .number(0.125)
        formattedColumnCell.format = XLCellFormat(numberFormat: .percent)

        let hiddenColumn = worksheet.column(5)
        hiddenColumn.width = 20
        hiddenColumn.hidden = true
        worksheet.cell(row: 1, column: 5).value = .text("hidden column")

        worksheet.column(6).width = 24
        worksheet.cell(row: 1, column: 6).value = .text("column E is hidden")

        let bestFitColumn = worksheet.column(7)
        bestFitColumn.width = 18
        bestFitColumn.bestFit = true
        worksheet.cell(row: 1, column: 7).value = .text("bestFit=true")

        let outlineColumn = worksheet.column(8)
        outlineColumn.width = 18
        outlineColumn.outlineLevel = 1
        worksheet.cell(row: 1, column: 8).value = .text("outlineLevel=1")

        let collapsedColumn = worksheet.column(9)
        collapsedColumn.width = 18
        collapsedColumn.collapsed = true
        worksheet.cell(row: 1, column: 9).value = .text("collapsed=true")
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
            labelCell.value = .text("builtin \(example.id)")

            let symbolCell = worksheet.cell(row: index + 1, column: 2)
            symbolCell.value = .text(example.symbol)

            let valueCell = worksheet.cell(row: index + 1, column: 3)
            valueCell.value = .number(example.value)
            valueCell.format = XLCellFormat(numberFormat: example.numberFormat)
        }

        let customFormat = #"yyyy"ねん" m"がつ" d"にち""#
        let customRow = examples.count + 2
        worksheet.cell(row: customRow, column: 1).value = .text("custom")
        worksheet.cell(row: customRow, column: 2).value = .text(customFormat)

        let valueCell = worksheet.cell(row: customRow, column: 3)
        valueCell.value = .number(45825)
        valueCell.format = XLCellFormat(numberFormat: .format(customFormat))
    }

    private static func writeFontExamples(to worksheet: XLWorksheet) {
        worksheet.column(1).width = 24

        let examples: [(String, XLFont)] = [
            ("bold", XLFont(bold: true)),
            ("italic", XLFont(italic: true)),
            ("strike", XLFont(strike: true)),
            ("condense", XLFont(condense: true)),
            ("extend", XLFont(extend: true)),
            ("outline", XLFont(outline: true)),
            ("shadow", XLFont(shadow: true)),
            ("size", XLFont(size: 18)),
            ("name", XLFont(name: "Courier New")),
            ("RGB red", XLFont(color: .rgb("FFFF0000"))),
            ("indexed red", XLFont(color: .indexed(10))),
            ("theme accent", XLFont(color: .theme(4))),
            ("theme accent tint", XLFont(color: .theme(4, tint: 0.5))),
            ("automatic color", XLFont(color: .auto)),
        ]

        for (index, example) in examples.enumerated() {
            let cell = worksheet.cell(row: index + 1, column: 1)
            cell.value = .text(example.0)
            cell.format = XLCellFormat(font: example.1)
        }
    }

    private static func writeFillExamples(to worksheet: XLWorksheet) {
        worksheet.column(1).width = 24
        worksheet.column(2).width = 24

        let patterns: [XLFill.PatternType] = [
            .none,
            .solid,
            .mediumGray,
            .darkGray,
            .lightGray,
            .darkHorizontal,
            .darkVertical,
            .darkDown,
            .darkUp,
            .darkGrid,
            .darkTrellis,
            .lightHorizontal,
            .lightVertical,
            .lightDown,
            .lightUp,
            .lightGrid,
            .lightTrellis,
            .gray125,
            .gray0625,
        ]

        for (index, pattern) in patterns.enumerated() {
            let row = index + 1
            worksheet.cell(row: row, column: 1).value = .text(pattern.rawValue)

            let sampleCell = worksheet.cell(row: row, column: 2)
            sampleCell.value = .text("sample")
            sampleCell.format = XLCellFormat(fill: .pattern(XLFill.Pattern(
                patternType: pattern,
                foregroundColor: .rgb("FF5B9BD5"),
                backgroundColor: .rgb("FFFFFFFF")
            )))
        }
    }

    private static func writeBorderExamples(to worksheet: XLWorksheet) {
        worksheet.column(1).width = 18
        worksheet.column(2).width = 22
        worksheet.column(4).width = 24
        worksheet.column(5).width = 22

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
            ("diagonal both", XLBorder(diagonal: XLBorder.Diagonal(directions: [.up, .down], line: line))),
            ("medium", XLBorder(left: mediumLine, right: mediumLine, top: mediumLine, bottom: mediumLine)),
        ]

        for (index, example) in examples.enumerated() {
            let cell = worksheet.cell(row: (index + 1) * 2, column: 2)
            cell.value = .text(example.0)
            cell.format = XLCellFormat(border: example.1)
        }

        let lineStyles: [XLBorder.LineStyle] = [
            .none,
            .thin,
            .medium,
            .dashed,
            .dotted,
            .thick,
            .double,
            .hair,
            .mediumDashed,
            .dashDot,
            .mediumDashDot,
            .dashDotDot,
            .mediumDashDotDot,
            .slantDashDot,
        ]

        for (index, style) in lineStyles.enumerated() {
            let row = index + 1
            worksheet.cell(row: row, column: 4).value = .text(style.rawValue)

            let sampleCell = worksheet.cell(row: row, column: 5)
            sampleCell.value = .text("sample")
            sampleCell.format = XLCellFormat(border: XLBorder(
                bottom: XLBorder.Line(style: style, color: .rgb("FF000000"))
            ))
        }
    }

    private static func writeDataValidationExamples(to worksheet: XLWorksheet) {
        worksheet.column(1).width = 24
        worksheet.column(2).width = 20
        worksheet.column(3).width = 32
        worksheet.column(8).width = 18

        worksheet.cell(row: 1, column: 1).value = .text("validation type")
        worksheet.cell(row: 1, column: 2).value = .text("sample value")
        worksheet.cell(row: 1, column: 3).value = .text("valid input")

        worksheet.cell(row: 2, column: 1).value = .text("list")
        worksheet.cell(row: 2, column: 2).value = .text("Apple")
        worksheet.cell(row: 2, column: 3).value = .text("Apple, Banana, or Cherry")

        worksheet.cell(row: 3, column: 1).value = .text("whole")
        worksheet.cell(row: 3, column: 2).value = .number(5)
        worksheet.cell(row: 3, column: 3).value = .text("1 through 10")

        worksheet.cell(row: 4, column: 1).value = .text("decimal")
        worksheet.cell(row: 4, column: 2).value = .number(0.5)
        worksheet.cell(row: 4, column: 3).value = .text("0 through 1")

        worksheet.cell(row: 5, column: 1).value = .text("date")
        let dateCell = worksheet.cell(row: 5, column: 2)
        dateCell.value = .date(Date(timeIntervalSince1970: 0))
        dateCell.format = XLCellFormat(numberFormat: .date)
        worksheet.cell(row: 5, column: 3).value = .text("1960 through 2080")

        worksheet.cell(row: 6, column: 1).value = .text("time")
        let timeCell = worksheet.cell(row: 6, column: 2)
        timeCell.value = .number(0.5)
        timeCell.format = XLCellFormat(numberFormat: .time)
        worksheet.cell(row: 6, column: 3).value = .text("09:00 through 17:00")

        worksheet.cell(row: 7, column: 1).value = .text("text length")
        worksheet.cell(row: 7, column: 2).value = .text("Hello")
        worksheet.cell(row: 7, column: 3).value = .text("10 characters or fewer")

        worksheet.cell(row: 8, column: 1).value = .text("custom")
        worksheet.cell(row: 8, column: 2).value = .number(4)
        worksheet.cell(row: 8, column: 3).value = .text("even number")

        worksheet.cell(row: 10, column: 1).value = .text("list, second range")
        worksheet.cell(row: 10, column: 2).value = .text("Banana")
        worksheet.cell(row: 11, column: 2).value = .text("Cherry")
        worksheet.cell(row: 12, column: 2).value = .text("Apple")

        worksheet.cell(row: 1, column: 8).value = .text("list source")
        worksheet.cell(row: 2, column: 8).value = .text("Apple")
        worksheet.cell(row: 3, column: 8).value = .text("Banana")
        worksheet.cell(row: 4, column: 8).value = .text("Cherry")

        worksheet.dataValidation = XLDataValidations(
            validations: [
                XLDataValidation(
                    address: XLCellRangeAddressList([
                        XLCellRangeAddress(
                            start: XLCellAddress(row: 2, column: 2),
                            last: XLCellAddress(row: 2, column: 2)
                        ),
                        XLCellRangeAddress(
                            start: XLCellAddress(row: 10, column: 2),
                            last: XLCellAddress(row: 12, column: 2)
                        ),
                    ]),
                    validationType: .list,
                    showInputMessage: true,
                    errorTitle: "Invalid list value",
                    error: "Select a value from the list.",
                    promptTitle: "List validation",
                    prompt: "Select Apple, Banana, or Cherry.",
                    formula1: "$H$2:$H$4"
                ),
                XLDataValidation(
                    address: cellRangeAddressList(row: 3),
                    validationType: .whole,
                    validationOperator: .between,
                    errorStyle: .stop,
                    showInputMessage: true,
                    errorTitle: "Invalid whole number",
                    error: "Enter a whole number from 1 through 10.",
                    promptTitle: "Whole number",
                    prompt: "Enter 1 through 10.",
                    formula1: "1",
                    formula2: "10"
                ),
                XLDataValidation(
                    address: cellRangeAddressList(row: 4),
                    validationType: .decimal,
                    validationOperator: .between,
                    errorStyle: .warning,
                    showInputMessage: true,
                    errorTitle: "Decimal outside range",
                    error: "Enter a decimal from 0 through 1.",
                    promptTitle: "Decimal",
                    prompt: "Enter 0 through 1.",
                    formula1: "0",
                    formula2: "1"
                ),
                XLDataValidation(
                    address: cellRangeAddressList(row: 5),
                    validationType: .date,
                    validationOperator: .between,
                    showInputMessage: true,
                    errorTitle: "Invalid date",
                    error: "Enter a date from 1960 through 2080.",
                    promptTitle: "Date",
                    prompt: "Enter a date from 1960 through 2080.",
                    formula1: "DATE(1960,1,1)",
                    formula2: "DATE(2080,12,31)"
                ),
                XLDataValidation(
                    address: cellRangeAddressList(row: 6),
                    validationType: .time,
                    validationOperator: .between,
                    showInputMessage: true,
                    errorTitle: "Invalid time",
                    error: "Enter a time from 09:00 through 17:00.",
                    promptTitle: "Time",
                    prompt: "Enter a time from 09:00 through 17:00.",
                    formula1: "TIME(9,0,0)",
                    formula2: "TIME(17,0,0)"
                ),
                XLDataValidation(
                    address: cellRangeAddressList(row: 7),
                    validationType: .textLength,
                    validationOperator: .lessThanOrEqual,
                    imeMode: .hiragana,
                    showInputMessage: true,
                    errorTitle: "Text is too long",
                    error: "Enter 10 characters or fewer.",
                    promptTitle: "Text length",
                    prompt: "Enter 10 characters or fewer.",
                    formula1: "10"
                ),
                XLDataValidation(
                    address: cellRangeAddressList(row: 8),
                    validationType: .custom,
                    errorStyle: .information,
                    showInputMessage: true,
                    errorTitle: "Odd number",
                    error: "Enter an even number.",
                    promptTitle: "Custom validation",
                    prompt: "Enter an even number.",
                    formula1: "MOD(B8,2)=0"
                ),
            ]
        )
    }

    private static func writePasswordProtectionExamples(to worksheet: XLWorksheet) {
        worksheet.column(1).width = 24
        worksheet.column(2).width = 28

        worksheet.cell(row: 1, column: 1).value = .text("password:")
        worksheet.cell(row: 1, column: 2).value = .text("swift-xlsx")

        worksheet.cell(row: 3, column: 1).value = .text("locked cell")
        worksheet.cell(row: 3, column: 2).value = .text("cannot edit")

        worksheet.cell(row: 4, column: 1).value = .text("unlocked cell")
        let unlockedCell = worksheet.cell(row: 4, column: 2)
        unlockedCell.value = .text("can edit")
        unlockedCell.format = XLCellFormat(
            fill: .pattern(XLFill.Pattern(
                patternType: .solid,
                foregroundColor: .rgb("FFFFE699")
            )),
            protection: XLCellFormatProtection(locked: false)
        )

        worksheet.cell(row: 5, column: 1).value = .text("hidden formula")
        let hiddenFormulaCell = worksheet.cell(row: 5, column: 2)
        hiddenFormulaCell.value = .number(2)
        hiddenFormulaCell.formula = .regular("1+1")
        hiddenFormulaCell.format = XLCellFormat(protection: XLCellFormatProtection(hidden: true))

        worksheet.sheetProtection = XLSheetProtection(
            passwordHashInfo: XLSheetProtection.PasswordHashInfo.generate(
                password: "swift-xlsx",
                algorithm: .sha512,
                salt: Data("swift-xlsx-salt!".utf8)
            )
        )
    }

    private static func writeHiddenSheetExamples(to worksheet: XLWorksheet) {
        worksheet.cell(row: 1, column: 1).value = .text("hidden")
        worksheet.state = .hidden
    }

    private static func writeCellValueExamples(to worksheet: XLWorksheet) {
        worksheet.column(1).width = 24
        worksheet.column(2).width = 32
        worksheet.column(2).phonetic = true

        worksheet.cell(row: 1, column: 1).value = .text("plain text")
        worksheet.cell(row: 1, column: 2).value = .text("Hello, swift-xlsx")

        worksheet.cell(row: 2, column: 1).value = .text("rich text")
        worksheet.cell(row: 2, column: 2).value = .text(XLText(content: .rich([
            XLTextRun(text: "bold", font: XLFont(bold: true)),
            XLTextRun(text: " + "),
            XLTextRun(text: "red", font: XLFont(color: .rgb("FFFF0000"))),
        ])))

        worksheet.cell(row: 3, column: 1).value = .text("phonetic text")
        worksheet.cell(row: 3, column: 2).value = .text(XLText(
            content: .plain("漢字"),
            phoneticRuns: [
                XLPhoneticRun(text: "かんじ", startIndex: 0, endIndex: 2),
            ],
            phoneticProperties: XLPhoneticProperties(
                fontID: 0,
                type: "Hiragana",
                alignment: "center"
            )
        ))

        worksheet.cell(row: 4, column: 1).value = .text("number")
        worksheet.cell(row: 4, column: 2).value = .number(1234.5)

        worksheet.cell(row: 5, column: 1).value = .text("boolean true")
        worksheet.cell(row: 5, column: 2).value = .boolean(true)

        worksheet.cell(row: 6, column: 1).value = .text("boolean false")
        worksheet.cell(row: 6, column: 2).value = .boolean(false)

        worksheet.cell(row: 7, column: 1).value = .text("date")
        let dateCell = worksheet.cell(row: 7, column: 2)
        dateCell.value = .date(Date(timeIntervalSince1970: 0))
        dateCell.format = XLCellFormat(numberFormat: .date)

        worksheet.cell(row: 8, column: 1).value = .text("error")
        worksheet.cell(row: 8, column: 2).value = .error("#N/A")
    }

    private static func writeFreezePanesExamples(to worksheet: XLWorksheet) {
        worksheet.frozenPanes = XLFrozenPanes(rowCount: 1, columnCount: 1)
        worksheet.column(1).width = 14
        for column in 2...10 {
            worksheet.column(column).width = 12
        }

        worksheet.cell(row: 1, column: 1).value = .text("row")
        for column in 2...10 {
            worksheet.cell(row: 1, column: column).value = .text("column \(column)")
        }

        for row in 2...50 {
            worksheet.cell(row: row, column: 1).value = .text("row \(row)")
            for column in 2...10 {
                worksheet.cell(row: row, column: column).value = .number(Double(row * 100 + column))
            }
        }
    }

    private static func writeCellStyleExamples(document: XLDocument, worksheet: XLWorksheet) {
        worksheet.column(1).width = 24
        worksheet.column(2).width = 32

        let namedStyleFont = XLFont(bold: true, color: .rgb("FFFFFFFF"))
        let namedStyleFill = XLFill.pattern(XLFill.Pattern(
            patternType: .solid,
            foregroundColor: .rgb("FF4472C4")
        ))
        let namedStyleBorder = XLBorder(
            left: XLBorder.Line(style: .thin),
            right: XLBorder.Line(style: .thin),
            top: XLBorder.Line(style: .thin),
            bottom: XLBorder.Line(style: .thin)
        )
        let namedStyleFormat = XLCellStyleFormatRef(
            numberFormat: .percent,
            font: namedStyleFont,
            fill: namedStyleFill,
            border: namedStyleBorder
        )
        document.package.styles.file.cellStyles.append(XLCellStyle(
            name: "Example Percent",
            format: namedStyleFormat
        ))

        worksheet.cell(row: 1, column: 1).value = .text("named cell style")
        let namedStyleCell = worksheet.cell(row: 1, column: 2)
        namedStyleCell.value = .number(0.125)
        namedStyleCell.format = XLCellFormat(
            numberFormat: .percent,
            font: namedStyleFont,
            fill: namedStyleFill,
            border: namedStyleBorder,
            styleFormat: namedStyleFormat
        )

        worksheet.cell(row: 3, column: 1).value = .text("combined cell format")
        let combinedFormatCell = worksheet.cell(row: 3, column: 2)
        combinedFormatCell.value = .number(1234.5)
        combinedFormatCell.format = XLCellFormat(
            numberFormat: .thousandsDecimal2,
            font: XLFont(bold: true, color: .rgb("FF9C0006")),
            fill: .pattern(XLFill.Pattern(
                patternType: .solid,
                foregroundColor: .rgb("FFFFC7CE")
            )),
            border: XLBorder(bottom: XLBorder.Line(style: .double))
        )
    }

    private static func writeVeryHiddenSheetExamples(to worksheet: XLWorksheet) {
        worksheet.cell(row: 1, column: 1).value = .text("very hidden")
        worksheet.state = .veryHidden
    }

    private static func cellRangeAddressList(row: Int, column: Int = 2) -> XLCellRangeAddressList {
        XLCellRangeAddressList([
            XLCellRangeAddress(
                start: XLCellAddress(row: row, column: column),
                last: XLCellAddress(row: row, column: column)
            ),
        ])
    }
}
