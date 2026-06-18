import Testing
import XLSX
import XLSXXML

@Suite
struct XLFormulaRecordTests {
    @Test func parsesFormulaRecordFromFormulaElement() throws {
        let formulaElement = XMLElement(
            name: XMLName(name: "f"),
            attributes: [
                XMLAttribute(name: XMLName(name: "t"), value: "shared"),
                XMLAttribute(name: XMLName(name: "si"), value: "3"),
                XMLAttribute(name: XMLName(name: "ref"), value: "A1:B2"),
                XMLAttribute(name: XMLName(name: "ca"), value: "1"),
            ],
            children: [
                XMLText("SUM(A1:A2)"),
            ]
        )

        let record = XLFormulaRecord(formulaElement: formulaElement)

        #expect(record.formula == "SUM(A1:A2)")
        #expect(record.kind == .shared)
        #expect(record.sharedIndex == 3)
        #expect(record.reference == XLCellRangeAddress("A1:B2"))
        #expect(record.opaqueAttributes.count == 1)
        #expect(record.opaqueAttributes.first?.name == XMLName(name: "ca"))
        #expect(record.opaqueAttributes.first?.value == "1")
    }

    @Test func writesFormulaRecordToFormulaElement() throws {
        let record = XLFormulaRecord(
            formula: "SUM(A1:A2)",
            kind: .array,
            sharedIndex: nil,
            reference: XLCellRangeAddress("A1:B2"),
            opaqueAttributes: [
                XMLAttribute(name: XMLName(name: "ca"), value: "1"),
            ]
        )

        let formulaElement = record.xmlElement()

        #expect(formulaElement.name == XMLName(name: "f"))
        #expect(formulaElement.attribute(name: "t") == "array")
        #expect(formulaElement.attribute(name: "si") == nil)
        #expect(formulaElement.attribute(name: "ref") == "A1:B2")
        #expect(formulaElement.attribute(name: "ca") == "1")
        #expect(formulaElement.children.compactMap { ($0 as? XMLText)?.value } == ["SUM(A1:A2)"])
    }
}
