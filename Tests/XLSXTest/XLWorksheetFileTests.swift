import Foundation
import Testing
import XLSX

@Suite
struct XLWorksheetFileTests {
    @Test func cellValueReadsAndWritesPrimitiveValueStrings() {
        #expect(XLCellValue.booleanValue(string: "1") == true)
        #expect(XLCellValue.booleanValue(string: "FALSE") == false)
        #expect(XLCellValue.booleanString(value: true) == "1")
        #expect(XLCellValue.booleanString(value: false) == "0")

        #expect(XLCellValue.numberValue(string: "42") == 42)
        #expect(XLCellValue.numberValue(string: "3.14") == 3.14)
        #expect(XLCellValue.numberValue(string: "text") == nil)
        #expect(XLCellValue.numberString(value: 42) == "42")
        #expect(XLCellValue.numberString(value: 3.14) == "3.14")
    }

    @Test func cellValueConvertsExcelSerialNumbersAndDates() {
        #expect(XLCellValue.dateValue(number: 1) == utcDate(year: 1900, month: 1, day: 1))
        #expect(XLCellValue.dateValue(number: 59) == utcDate(year: 1900, month: 2, day: 28))
        #expect(XLCellValue.dateValue(number: 61) == utcDate(year: 1900, month: 3, day: 1))
        #expect(XLCellValue.dateValue(number: 61.5) == utcDate(year: 1900, month: 3, day: 1, hour: 12))

        #expect(XLCellValue.numberValue(date: utcDate(year: 1900, month: 1, day: 1)) == 1)
        #expect(XLCellValue.numberValue(date: utcDate(year: 1900, month: 2, day: 28)) == 59)
        #expect(XLCellValue.numberValue(date: utcDate(year: 1900, month: 3, day: 1)) == 61)
        #expect(XLCellValue.numberValue(date: utcDate(year: 1900, month: 3, day: 1, hour: 12)) == 61.5)
    }

    @Test func cellValueCaseAccessorsReturnAssociatedValues() {
        #expect(XLCellValue.number(42).number == 42)
        #expect(XLCellValue.date(utcDate(year: 1900, month: 3, day: 1)) == .number(61))
        #expect(XLCellValue.number(61.5).date == utcDate(year: 1900, month: 3, day: 1, hour: 12))
        #expect(XLCellValue.date(utcDate(year: 1900, month: 3, day: 1, hour: 12)).date == utcDate(year: 1900, month: 3, day: 1, hour: 12))
        #expect(XLCellValue.boolean(true).boolean == true)
        #expect(XLCellValue.string("text").string == "text")
        #expect(XLCellValue.error("#N/A").error == "#N/A")
        #expect(
            XLCellValue.opaqueSharedString(xmlString: "<r><t>rich</t></r>").opaqueSharedString ==
                "<r><t>rich</t></r>"
        )

        #expect(XLCellValue.number(42).string == nil)
        #expect(XLCellValue.string("text").number == nil)
        #expect(XLCellValue.string("text").date == nil)
    }

    @Test func readsSparseRowsAndCellsFromWorksheetXML() throws {
        let worksheet = try worksheetFile(data: Data("""
            <worksheet xmlns="\(XMLNamespaceURI.spreadsheet.string)">
              <sheetData>
                <row r="2">
                  <c r="B2"><v>left</v></c>
                  <c r="D2"><v>right</v></c>
                </row>
                <row r="10">
                  <c r="C10"><v>bottom</v></c>
                </row>
              </sheetData>
            </worksheet>
            """.utf8))

        #expect(worksheet.existingRowNumbers == [2, 10])
        #expect(worksheet.existingRow(2)?.existingColumnNumbers == [2, 4])
        #expect(worksheet.existingRow(2)?.existingCell(column: 2)?.value == .string("left"))
        #expect(worksheet.existingRow(2)?.existingCell(column: 4)?.value == .string("right"))
        #expect(worksheet.existingRow(10)?.existingColumnNumbers == [3])
        #expect(worksheet.existingRow(10)?.existingCell(column: 3)?.value == .string("bottom"))
    }

    @Test func readsColumnsFromWorksheetXML() throws {
        let worksheet = try worksheetFile(data: Data("""
            <worksheet xmlns="\(XMLNamespaceURI.spreadsheet.string)">
              <cols>
                <col min="2" max="4" width="20" customWidth="1"/>
                <col min="7" max="7" width="12.5" customWidth="1"/>
              </cols>
              <sheetData/>
            </worksheet>
            """.utf8))

        #expect(worksheet.existingColumnNumbers == [2, 3, 4, 7])
        #expect(worksheet.existingColumn(2)?.width == 20)
        #expect(worksheet.existingColumn(3)?.width == 20)
        #expect(worksheet.existingColumn(4)?.width == 20)
        #expect(worksheet.existingColumn(7)?.width == 12.5)
    }

    @Test func readsColumnAttributesFromWorksheetXML() throws {
        let worksheet = try worksheetFile(data: Data("""
            <worksheet xmlns="\(XMLNamespaceURI.spreadsheet.string)">
              <cols>
                <col min="2" max="2" width="20" customWidth="1" hidden="1" bestFit="1" outlineLevel="2" collapsed="1" phonetic="1"/>
              </cols>
              <sheetData/>
            </worksheet>
            """.utf8))
        let column = try #require(worksheet.existingColumn(2))

        #expect(column.width == 20)
        #expect(column.customWidth == true)
        #expect(column.hidden == true)
        #expect(column.bestFit == true)
        #expect(column.outlineLevel == 2)
        #expect(column.collapsed == true)
        #expect(column.phonetic == true)
    }

    @Test func readsColumnFormatsFromWorksheetXML() throws {
        let worksheet = try XLWorksheetFile(
            xmlDocument: XMLDocument(data: Data("""
                <worksheet xmlns="\(XMLNamespaceURI.spreadsheet.string)">
                  <cols>
                    <col min="2" max="2" style="1"/>
                  </cols>
                  <sheetData/>
                </worksheet>
                """.utf8)),
            sharedStrings: XLSharedStringsFile(),
            styles: XLStylesFile(xmlDocument: XMLDocument(data: Data("""
                <styleSheet xmlns="\(XMLNamespaceURI.spreadsheet.string)">
                  <cellXfs count="2">
                    <xf numFmtId="0"/>
                    <xf numFmtId="14" applyNumberFormat="1"/>
                  </cellXfs>
                </styleSheet>
                """.utf8)))
        )

        #expect(worksheet.existingColumn(2)?.format == XLCellFormat(
            numberFormat: .builtin(id: 14),
            applyNumberFormat: true
        ))
    }

    @Test func readsCellValueTypesFromWorksheetXML() throws {
        let worksheet = try worksheetFile(data: Data("""
            <worksheet xmlns="\(XMLNamespaceURI.spreadsheet.string)">
              <sheetData>
                <row r="1">
                  <c r="A1"><v>42</v></c>
                  <c r="B1" t="n"><v>3.14</v></c>
                  <c r="C1" t="b"><v>1</v></c>
                  <c r="D1" t="e"><v>#DIV/0!</v></c>
                  <c r="E1" t="d"><v>2026-06-16T09:30:00Z</v></c>
                  <c r="F1" t="inlineStr"><is><t>inline</t></is></c>
                  <c r="G1" t="str"><f>TEXT(1,"0")</f><v>cached</v></c>
                  <c r="H1" t="s"><v>5</v></c>
                  <c r="I1" t="b"><v>0</v></c>
                  <c r="J1" t="b"><v>-2</v></c>
                  <c r="K1" t="b"><v>Yes</v></c>
                  <c r="L1" t="b"><v>FALSE</v></c>
                  <c r="M1"><v>45292.5</v></c>
                </row>
              </sheetData>
            </worksheet>
            """.utf8))

        #expect(worksheet.existingRow(1)?.existingCell(column: 1)?.value == .number(42))
        #expect(worksheet.existingRow(1)?.existingCell(column: 2)?.value == .number(3.14))
        #expect(worksheet.existingRow(1)?.existingCell(column: 3)?.value == .boolean(true))
        #expect(worksheet.existingRow(1)?.existingCell(column: 4)?.value == .error("#DIV/0!"))
        #expect(worksheet.existingRow(1)?.existingCell(column: 5)?.value == .string("2026-06-16T09:30:00Z"))
        #expect(worksheet.existingRow(1)?.existingCell(column: 6)?.value == .string("inline"))
        #expect(worksheet.existingRow(1)?.existingCell(column: 7)?.value == .string("cached"))
        if case let .regular(formula) = worksheet.formula(at: XLCellAddress(row: 1, column: 7)) {
            #expect(formula == #"TEXT(1,"0")"#)
        } else {
            Issue.record("Expected regular formula.")
        }
        #expect(worksheet.existingRow(1)?.existingCell(column: 8) == nil)
        #expect(worksheet.existingRow(1)?.existingCell(column: 9)?.value == .boolean(false))
        #expect(worksheet.existingRow(1)?.existingCell(column: 10)?.value == .boolean(true))
        #expect(worksheet.existingRow(1)?.existingCell(column: 11)?.value == .boolean(true))
        #expect(worksheet.existingRow(1)?.existingCell(column: 12)?.value == .boolean(false))
        #expect(worksheet.existingRow(1)?.existingCell(column: 13)?.value == .number(45292.5))
    }

    @Test func ignoresStandaloneWorksheetCellFormatWithoutStyles() throws {
        let worksheet = try worksheetFile(data: Data("""
            <worksheet xmlns="\(XMLNamespaceURI.spreadsheet.string)">
              <sheetData>
                <row r="1">
                  <c r="A1" s="2"><v>42</v></c>
                  <c r="B1" t="s" s="3"><v>0</v></c>
                </row>
              </sheetData>
            </worksheet>
            """.utf8))

        #expect(worksheet.existingRow(1)?.existingCell(column: 1)?.format == nil)
        #expect(worksheet.existingRow(1)?.existingCell(column: 2) == nil)
    }

    @Test func writesSparseRowsAndCellsToWorksheetXML() throws {
        let worksheet = XLWorksheetFile(rowByNumber: [
            10: XLRowStorage(cellByColumn: [
                3: XLCellStorage(value: .string("bottom")),
            ]),
            2: XLRowStorage(cellByColumn: [
                4: XLCellStorage(value: .string("right")),
                2: XLCellStorage(value: .string("left")),
            ]),
        ])

        let xml = try String(decoding: worksheet.xmlDocument().data, as: UTF8.self)

        #expect(xml.contains(#"<sheetData><row r="2"><c r="B2"><v>left</v></c><c r="D2"><v>right</v></c></row><row r="10"><c r="C10"><v>bottom</v></c></row></sheetData>"#))
    }

    @Test func writesColumnsToWorksheetXML() throws {
        let worksheet = XLWorksheetFile(
            columnByNumber: [
                4: XLColumnStorage(width: 8.5),
                2: XLColumnStorage(width: 20),
            ],
            rowByNumber: [:]
        )

        let xml = try String(decoding: worksheet.xmlDocument().data, as: UTF8.self)

        #expect(xml.contains(#"<cols><col min="2" max="2" width="20.0" customWidth="1"/><col min="4" max="4" width="8.5" customWidth="1"/></cols>"#))
    }

    @Test func writesConsecutiveEquivalentColumnsAsRange() throws {
        let worksheet = XLWorksheetFile(
            columnByNumber: [
                5: XLColumnStorage(width: 12),
                4: XLColumnStorage(width: 8.5),
                3: XLColumnStorage(width: 8.5),
                2: XLColumnStorage(width: 8.5),
            ],
            rowByNumber: [:]
        )

        let xml = try String(decoding: worksheet.xmlDocument().data, as: UTF8.self)

        #expect(xml.contains(#"<cols><col min="2" max="4" width="8.5" customWidth="1"/><col min="5" max="5" width="12.0" customWidth="1"/></cols>"#))
    }

    @Test func writesColumnAttributesToWorksheetXML() throws {
        let worksheet = XLWorksheetFile(
            columnByNumber: [
                2: XLColumnStorage(
                    width: 20,
                    customWidth: false,
                    hidden: true,
                    bestFit: true,
                    outlineLevel: 2,
                    collapsed: true,
                    phonetic: true
                ),
            ],
            rowByNumber: [:]
        )

        let xml = try String(decoding: worksheet.xmlDocument().data, as: UTF8.self)

        #expect(xml.contains(#"<cols><col min="2" max="2" width="20.0" customWidth="0" hidden="1" bestFit="1" outlineLevel="2" collapsed="1" phonetic="1"/></cols>"#))
    }

    @Test func columnRangeUsesAllColumnAttributesForEquivalence() throws {
        let worksheet = XLWorksheetFile(
            columnByNumber: [
                2: XLColumnStorage(width: 20, hidden: true),
                3: XLColumnStorage(width: 20, hidden: true),
                4: XLColumnStorage(width: 20, hidden: false),
            ],
            rowByNumber: [:]
        )

        let xml = try String(decoding: worksheet.xmlDocument().data, as: UTF8.self)

        #expect(xml.contains(#"<cols><col min="2" max="3" width="20.0" customWidth="1" hidden="1"/><col min="4" max="4" width="20.0" customWidth="1" hidden="0"/></cols>"#))
    }

    @Test func removesColumnFormatWhenStandaloneWorksheetHasNoWritePlan() throws {
        let worksheet = try worksheetFile(data: Data("""
            <worksheet xmlns="\(XMLNamespaceURI.spreadsheet.string)">
              <cols>
                <col min="2" max="2" width="20" customWidth="1" style="1"/>
              </cols>
              <sheetData/>
            </worksheet>
            """.utf8))

        let xml = try String(decoding: worksheet.xmlDocument().data, as: UTF8.self)

        #expect(xml.contains(#"<col min="2" max="2" width="20.0" customWidth="1"/>"#))
    }

    @Test func writesColumnsBeforeSheetData() throws {
        let worksheet = try worksheetFile(data: Data("""
            <worksheet xmlns="\(XMLNamespaceURI.spreadsheet.string)">
              <sheetData>
                <row r="1"><c r="A1"><v>1</v></c></row>
              </sheetData>
            </worksheet>
            """.utf8))

        worksheet.column(2).width = 20

        let xml = try String(decoding: worksheet.xmlDocument().data, as: UTF8.self)

        let colsRange = try #require(xml.range(of: #"<cols>"#))
        let sheetDataRange = try #require(xml.range(of: #"<sheetData>"#))

        #expect(colsRange.lowerBound < sheetDataRange.lowerBound)
    }

    @Test func writesCellValueTypesToWorksheetXML() throws {
        let worksheet = XLWorksheetFile(rowByNumber: [
            1: XLRowStorage(cellByColumn: [
                1: XLCellStorage(value: .number(42)),
                2: XLCellStorage(value: .boolean(false)),
                3: XLCellStorage(value: .error("#N/A")),
            ]),
        ])

        let xml = try String(decoding: worksheet.xmlDocument().data, as: UTF8.self)

        #expect(xml.contains(#"<c r="A1"><v>42</v></c>"#))
        #expect(xml.contains(#"<c r="B1" t="b"><v>0</v></c>"#))
        #expect(xml.contains(#"<c r="C1" t="e"><v>#N/A</v></c>"#))
    }

    @Test func writesFormulaCellsToWorksheetXML() throws {
        let worksheet = XLWorksheetFile(rowByNumber: [
            1: XLRowStorage(cellByColumn: [
                1: XLCellStorage(
                    value: .number(42),
                    formula: .regular("SUM(B1:C1)")
                ),
                2: XLCellStorage(
                    value: .string("cached"),
                    formula: .regular(#"TEXT(1,"0")"#)
                ),
            ]),
        ])

        let xml = try String(decoding: worksheet.xmlDocument().data, as: UTF8.self)

        #expect(xml.contains(#"<c r="A1"><f t="normal">SUM(B1:C1)</f><v>42</v></c>"#))
        #expect(xml.contains(#"<c r="B1" t="str"><f t="normal">TEXT(1,"0")</f><v>cached</v></c>"#))
    }

    @Test func readsSharedFormulaReferencesAsDefinitionAddresses() throws {
        let worksheet = try worksheetFile(data: Data("""
            <worksheet xmlns="\(XMLNamespaceURI.spreadsheet.string)">
              <sheetData>
                <row r="1">
                  <c r="A1"><f t="shared" si="4" ref="A1:A2">B1+C1</f><v>3</v></c>
                </row>
                <row r="2">
                  <c r="A2"><f t="shared" si="4"/><v>7</v></c>
                </row>
              </sheetData>
            </worksheet>
            """.utf8))

        if case let .sharedDefinition(definition) = worksheet.formula(at: XLCellAddress(row: 1, column: 1)) {
            #expect(definition.formula == "B1+C1")
            #expect(definition.reference == XLCellRangeAddress("A1:A2"))
        } else {
            Issue.record("Expected shared formula definition.")
        }

        if case let .sharedReference(address) = worksheet.formula(at: XLCellAddress(row: 2, column: 1)) {
            #expect(address == XLCellAddress(row: 1, column: 1))
        } else {
            Issue.record("Expected shared formula reference.")
        }
    }

    @Test func writesSharedFormulaReferencesWithGeneratedSharedIndex() throws {
        let worksheet = XLWorksheetFile(rowByNumber: [
            1: XLRowStorage(cellByColumn: [
                1: XLCellStorage(
                    value: .number(3),
                    formula: .sharedDefinition(XLSharedFormulaDefinition(
                        formula: "B1+C1",
                        reference: XLCellRangeAddress("A1:A2")
                    ))
                ),
            ]),
            2: XLRowStorage(cellByColumn: [
                1: XLCellStorage(
                    value: .number(7),
                    formula: .sharedReference(address: XLCellAddress(row: 1, column: 1))
                ),
            ]),
        ])

        let xml = try String(decoding: worksheet.xmlDocument().data, as: UTF8.self)

        #expect(xml.contains(#"<c r="A1"><f t="shared" si="0" ref="A1:A2">B1+C1</f><v>3</v></c>"#))
        #expect(xml.contains(#"<c r="A2"><f t="shared" si="0"/><v>7</v></c>"#))
    }

    @Test func writesDanglingSharedFormulaReferencesAsCellsWithoutFormula() throws {
        let worksheet = XLWorksheetFile(rowByNumber: [
            1: XLRowStorage(cellByColumn: [
                1: XLCellStorage(
                    value: .number(7),
                    formula: .sharedReference(address: XLCellAddress(row: 3, column: 1))
                ),
            ]),
        ])

        let xml = try String(decoding: worksheet.xmlDocument().data, as: UTF8.self)

        #expect(xml.contains(#"<c r="A1"><v>7</v></c>"#))
        #expect(!xml.contains(#"<f"#))
    }

    @Test func keepsDanglingSharedFormulaReferencesInModelWithoutWritingFormula() throws {
        let document = XLDocument()
        let worksheet = try #require(document.workbook.worksheets.first)
        let definitionCell = worksheet.cell(row: 1, column: 1)
        let referenceCell = worksheet.cell(row: 2, column: 1)
        definitionCell.value = .number(3)
        referenceCell.value = .number(7)

        definitionCell.formula = .sharedDefinition(XLSharedFormulaDefinition(
            formula: "B1+C1",
            reference: XLCellRangeAddress("A1:A2")
        ))
        referenceCell.formula = .sharedReference(address: definitionCell.address)

        if case let .sharedReference(address) = referenceCell.formula {
            #expect(address == definitionCell.address)
        } else {
            Issue.record("Expected shared formula reference.")
        }

        definitionCell.formula = .regular("B1+C1")

        if case let .sharedReference(address) = referenceCell.formula {
            #expect(address == definitionCell.address)
        } else {
            Issue.record("Expected dangling shared formula reference to remain in the model.")
        }

        let xml = try String(decoding: worksheet.file.xmlDocument().data, as: UTF8.self)
        #expect(xml.contains(#"<c r="A1"><f t="normal">B1+C1</f><v>3</v></c>"#))
        #expect(xml.contains(#"<c r="A2"><v>7</v></c>"#))
    }

    @Test func dropsInvalidOpaqueFormulaXMLWhenSettingFormula() throws {
        let document = XLDocument()
        let worksheet = try #require(document.workbook.worksheets.first)
        let cell = worksheet.cell(row: 1, column: 1)
        cell.value = .number(7)

        cell.formula = .array(xmlString: "<notFormula/>")
        var xml = try String(decoding: worksheet.file.xmlDocument().data, as: UTF8.self)
        #expect(xml.contains(#"<c r="A1"><v>7</v></c>"#))
        #expect(!xml.contains(#"<f"#))

        cell.formula = .dataTable(xmlString: "<f")
        xml = try String(decoding: worksheet.file.xmlDocument().data, as: UTF8.self)
        #expect(xml.contains(#"<c r="A1"><v>7</v></c>"#))
        #expect(!xml.contains(#"<f"#))
    }

    @Test func removesCellFormatWhenStandaloneWorksheetHasNoWritePlan() throws {
        let format = XLCellFormat(numberFormat: .builtin(id: 14), applyNumberFormat: true)
        let formattedCell = XLCellStorage(value: .number(42), format: format)
        let worksheet = XLWorksheetFile(rowByNumber: [
            1: XLRowStorage(cellByColumn: [
                1: formattedCell,
            ]),
        ])

        let xml = try String(decoding: worksheet.xmlDocument().data, as: UTF8.self)

        #expect(xml.contains(#"<c r="A1"><v>42</v></c>"#))
    }

    @Test func writesStringCellsToSharedStringsWhenSavingDocument() throws {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("swift-xlsx-tests-\(UUID().uuidString)")
            .appendingPathExtension("xlsx")
        defer {
            try? FileManager.default.removeItem(at: url)
        }

        let document = XLDocument()
        let worksheet = try #require(document.workbook.worksheets.first)
        worksheet.cell(row: 1, column: 1).value = .string("shared")
        try document.save(to: url)

        #expect(worksheet.existingRow(1)?.existingCell(column: 1)?.value == .string("shared"))
        #expect(document.package.sharedStrings.file.records.isEmpty)

        let package = try OPCPackage(data: Data(contentsOf: url))
        let worksheetXML = try String(
            decoding: #require(package.data(at: OPCFilePath(string: "/xl/worksheets/sheet1.xml"))),
            as: UTF8.self
        )
        let sharedStringsXML = try String(
            decoding: #require(package.data(at: OPCFilePath(string: "/xl/sharedStrings.xml"))),
            as: UTF8.self
        )

        #expect(worksheetXML.contains(#"<c r="A1" t="s"><v>0</v></c>"#))
        #expect(sharedStringsXML.contains(#"<t>shared</t>"#))
    }

    @Test func writesFormulaStringCachedValuesWithoutSharedStringsWhenSavingDocument() throws {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("swift-xlsx-tests-\(UUID().uuidString)")
            .appendingPathExtension("xlsx")
        defer {
            try? FileManager.default.removeItem(at: url)
        }

        let document = XLDocument()
        let worksheet = try #require(document.workbook.worksheets.first)
        let cell = worksheet.cell(row: 1, column: 1)
        cell.value = .string("cached")
        cell.formula = .regular(#"TEXT(1,"0")"#)
        try document.save(to: url)

        let package = try OPCPackage(data: Data(contentsOf: url))
        let worksheetXML = try String(
            decoding: #require(package.data(at: OPCFilePath(string: "/xl/worksheets/sheet1.xml"))),
            as: UTF8.self
        )
        let sharedStringsXML = try String(
            decoding: #require(package.data(at: OPCFilePath(string: "/xl/sharedStrings.xml"))),
            as: UTF8.self
        )

        #expect(worksheetXML.contains(#"<c r="A1" t="str"><f t="normal">TEXT(1,"0")</f><v>cached</v></c>"#))
        #expect(!sharedStringsXML.contains(#"<t>cached</t>"#))
    }

    @Test func writesDanglingSharedFormulaStringCachedValuesAsRegularSharedStrings() throws {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("swift-xlsx-tests-\(UUID().uuidString)")
            .appendingPathExtension("xlsx")
        defer {
            try? FileManager.default.removeItem(at: url)
        }

        let document = XLDocument()
        let worksheet = try #require(document.workbook.worksheets.first)
        let cell = worksheet.cell(row: 1, column: 1)
        cell.value = .string("cached")
        cell.formula = .sharedReference(address: XLCellAddress(row: 3, column: 1))
        try document.save(to: url)

        let package = try OPCPackage(data: Data(contentsOf: url))
        let worksheetXML = try String(
            decoding: #require(package.data(at: OPCFilePath(string: "/xl/worksheets/sheet1.xml"))),
            as: UTF8.self
        )
        let sharedStringsXML = try String(
            decoding: #require(package.data(at: OPCFilePath(string: "/xl/sharedStrings.xml"))),
            as: UTF8.self
        )

        #expect(worksheetXML.contains(#"<c r="A1" t="s"><v>0</v></c>"#))
        #expect(!worksheetXML.contains(#"<f"#))
        #expect(sharedStringsXML.contains(#"<t>cached</t>"#))
    }

    @Test func writesRowsSortedBeforeOtherSheetDataChildren() throws {
        let worksheet = try worksheetFile(data: Data("""
            <worksheet xmlns="\(XMLNamespaceURI.spreadsheet.string)">
              <sheetData>
                <row r="10">
                  <c r="C10"><v>bottom</v></c>
                </row>
                <marker/>
                <row r="2">
                  <c r="B2"><v>left</v></c>
                </row>
              </sheetData>
            </worksheet>
            """.utf8))

        worksheet.cell(row: 5, column: 1).value = .string("middle")

        let xml = try String(decoding: worksheet.xmlDocument().data, as: UTF8.self)

        let row2Range = try #require(xml.range(of: #"<row r="2""#))
        let row5Range = try #require(xml.range(of: #"<row r="5""#))
        let row10Range = try #require(xml.range(of: #"<row r="10""#))
        let markerRange = try #require(xml.range(of: #"<marker/>"#))

        #expect(row2Range.lowerBound < row5Range.lowerBound)
        #expect(row5Range.lowerBound < row10Range.lowerBound)
        #expect(row10Range.lowerBound < markerRange.lowerBound)
    }

    @Test func writesCellsSortedBeforeOtherRowChildren() throws {
        let worksheet = try worksheetFile(data: Data("""
            <worksheet xmlns="\(XMLNamespaceURI.spreadsheet.string)">
              <sheetData>
                <row r="2">
                  <c r="D2"><v>right</v></c>
                  <marker/>
                  <c r="B2"><v>left</v></c>
                </row>
              </sheetData>
            </worksheet>
            """.utf8))

        worksheet.cell(row: 2, column: 3).value = .string("middle")

        let xml = try String(decoding: worksheet.xmlDocument().data, as: UTF8.self)

        let cellBRange = try #require(xml.range(of: #"<c r="B2""#))
        let cellCRange = try #require(xml.range(of: #"<c r="C2""#))
        let cellDRange = try #require(xml.range(of: #"<c r="D2""#))
        let markerRange = try #require(xml.range(of: #"<marker/>"#))

        #expect(cellBRange.lowerBound < cellCRange.lowerBound)
        #expect(cellCRange.lowerBound < cellDRange.lowerBound)
        #expect(cellDRange.lowerBound < markerRange.lowerBound)
    }

    @Test func exposesExistingRowNumbersAndMaxRowNumber() {
        let worksheet = XLWorksheetFile(rowByNumber: [
            10: XLRowStorage(cellByColumn: [:]),
            2: XLRowStorage(cellByColumn: [:]),
        ])

        #expect(worksheet.maxRowNumber == 10)
        #expect(worksheet.existingRowNumbers == [2, 10])
        #expect(worksheet.existingRowsWithNumber.map(\.0) == [2, 10])
        #expect(worksheet.existingRows.map(\.cellByColumn.isEmpty) == [true, true])
    }

    @Test func exposesExistingColumnNumbersAndMaxColumnNumberFromWorksheet() {
        let worksheet = XLWorksheetFile(
            columnByNumber: [
                4: XLColumnStorage(width: 8.5),
                2: XLColumnStorage(width: 20),
            ],
            rowByNumber: [:]
        )

        #expect(worksheet.maxColumnNumber == 4)
        #expect(worksheet.existingColumnNumbers == [2, 4])
        #expect(worksheet.existingColumnsWithNumber.map(\.0) == [2, 4])
        #expect(worksheet.existingColumns.map(\.width) == [20, 8.5])
    }

    @Test func returnsExistingColumnsWithoutCreatingMissingColumns() {
        let worksheet = XLWorksheetFile(
            columnByNumber: [
                2: XLColumnStorage(width: 20),
            ],
            rowByNumber: [:]
        )

        #expect(worksheet.existingColumn(2)?.width == 20)
        #expect(worksheet.existingColumn(3) == nil)
        #expect(worksheet.existingColumnNumbers == [2])
    }

    @Test func createsMissingColumnsWhenAccessed() {
        let worksheet = XLWorksheetFile()

        #expect(worksheet.maxColumnNumber == nil)
        #expect(worksheet.existingColumn(3) == nil)

        #expect(worksheet.column(3).width == nil)
        #expect(worksheet.existingColumn(3)?.width == nil)
        #expect(worksheet.maxColumnNumber == 3)
        #expect(worksheet.existingColumnNumbers == [3])
    }

    @Test func returnsExistingRowsWithoutCreatingMissingRows() throws {
        let worksheet = XLWorksheetFile(rowByNumber: [
            2: XLRowStorage(cellByColumn: [
                1: XLCellStorage(value: .string("left")),
            ]),
        ])

        let row = try #require(worksheet.existingRow(2))
        #expect(row.existingColumnNumbers == [1])
        #expect(row.existingCell(column: 1)?.value == .string("left"))
        #expect(worksheet.existingRow(3) == nil)
        #expect(worksheet.existingRowNumbers == [2])
    }

    @Test func createsMissingRowsWhenAccessed() {
        let worksheet = XLWorksheetFile()

        #expect(worksheet.maxRowNumber == nil)
        #expect(worksheet.existingRow(3) == nil)

        #expect(worksheet.row(3).cellByColumn.isEmpty)
        #expect(worksheet.existingRow(3)?.cellByColumn.isEmpty == true)
        #expect(worksheet.maxRowNumber == 3)
        #expect(worksheet.existingRowNumbers == [3])
    }

    @Test func editsCellsThroughAccessedRow() {
        let worksheet = XLWorksheetFile()

        worksheet.row(3).cell(column: 2).value = .string("value")

        #expect(worksheet.existingRow(3)?.cellByColumn[2]?.value == .string("value"))
    }

    @Test func editsCellsThroughWorksheetCellAccessors() throws {
        let worksheet = XLWorksheetFile()

        worksheet.cell(row: 3, column: 2).value = .string("left")
        worksheet.cell(address: try #require(XLCellAddress("D4"))).value = .string("right")

        #expect(worksheet.existingRow(3)?.existingCell(column: 2)?.value == .string("left"))
        #expect(worksheet.existingRow(4)?.existingCell(column: 4)?.value == .string("right"))
    }

    @Test func exposesExistingColumnNumbersAndMaxColumnNumber() {
        let row = XLRowStorage(cellByColumn: [
            4: XLCellStorage(value: .string("right")),
            2: XLCellStorage(value: .string("left")),
        ])

        #expect(row.maxColumnNumber == 4)
        #expect(row.existingColumnNumbers == [2, 4])
    }

    @Test func returnsExistingCellsWithoutCreatingMissingCells() {
        let row = XLRowStorage(cellByColumn: [
            2: XLCellStorage(value: .string("left")),
        ])

        #expect(row.existingCell(column: 2)?.value == .string("left"))
        #expect(row.existingCell(column: 2)?.format == nil)
        #expect(row.existingCell(column: 3) == nil)
        #expect(row.existingColumnNumbers == [2])
    }

    @Test func createsMissingCellsWhenAccessed() {
        let row = XLRowStorage(cellByColumn: [:])

        #expect(row.maxColumnNumber == nil)
        #expect(row.existingCell(column: 3) == nil)

        #expect(row.cell(column: 3).value == .string(""))
        #expect(row.cell(column: 3).format == nil)
        #expect(row.existingCell(column: 3)?.value == .string(""))
        #expect(row.existingCell(column: 3)?.format == nil)
        #expect(row.maxColumnNumber == 3)
        #expect(row.existingColumnNumbers == [3])
    }

    @Test func patchesKnownCellsWithoutRemovingUnknownCellAttributes() throws {
        let worksheet = try worksheetFile(data: Data("""
            <worksheet xmlns="\(XMLNamespaceURI.spreadsheet.string)">
              <sheetData>
                <row r="1" custom="keep">
                  <c r="A1"><v>0</v></c>
                </row>
              </sheetData>
            </worksheet>
            """.utf8))
        worksheet.rowByNumber[1]?.cellByColumn[1]?.value = .string("1")

        let xml = try String(decoding: worksheet.xmlDocument().data, as: UTF8.self)

        #expect(xml.contains(#"<row r="1" custom="keep">"#))
        #expect(xml.contains(#"<c r="A1"><v>1</v></c>"#))
    }

    @Test func removesStandaloneWorksheetCellFormatWhenWritingWithoutPlan() throws {
        let worksheet = try worksheetFile(data: Data("""
            <worksheet xmlns="\(XMLNamespaceURI.spreadsheet.string)">
              <sheetData>
                <row r="1">
                  <c r="A1" s="2"><v>42</v></c>
                </row>
              </sheetData>
            </worksheet>
            """.utf8))

        let xml = try String(decoding: worksheet.xmlDocument().data, as: UTF8.self)

        #expect(xml.contains(#"<c r="A1"><v>42</v></c>"#))
    }

    private func worksheetFile(data: Data) throws -> XLWorksheetFile {
        try XLWorksheetFile(
            xmlDocument: XMLDocument(data: data),
            sharedStrings: XLSharedStringsFile(),
            styles: XLStylesFile()
        )
    }

    private func utcDate(
        year: Int,
        month: Int,
        day: Int,
        hour: Int = 0
    ) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar.date(from: DateComponents(
            timeZone: calendar.timeZone,
            year: year,
            month: month,
            day: day,
            hour: hour
        ))!
    }
}
