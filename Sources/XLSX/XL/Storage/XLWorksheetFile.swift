public final class XLWorksheetFile: OPCXMLFile {
    public init() {
        self.original = nil
        self.rowFromNumber = [:]
    }

    public init(rowFromNumber: [Int: XLRowStorage]) {
        self.original = nil
        self.rowFromNumber = rowFromNumber
    }

    public init(xmlDocument: XMLDocument) throws {
        self.original = xmlDocument
        self.rowFromNumber = Self.rows(in: xmlDocument)
    }

    public var original: XMLDocument?
    public var rowFromNumber: [Int: XLRowStorage]

    public var maxRowNumber: Int? {
        rowFromNumber.keys.max()
    }

    public var existingRowNumbers: [Int] {
        rowFromNumber.keys.sorted()
    }

    public func row(_ number: Int) -> XLRowStorage {
        if let row = rowFromNumber[number] {
            return row
        }

        let row = XLRowStorage(cellFromColumn: [:])
        rowFromNumber[number] = row
        return row
    }

    public func existingRow(_ number: Int) -> XLRowStorage? {
        rowFromNumber[number]
    }

    public func cell(row: Int, column: Int) -> XLCellStorage {
        self.row(row).cell(column: column)
    }

    public func cell(reference: XLCellReference) -> XLCellStorage {
        cell(row: reference.row, column: reference.column)
    }

    public func xmlDocument() -> XMLDocument {
        let document = original?.clone() ?? XMLDocument()
        let worksheetElement = worksheetElementForWriting(in: document)
        worksheetElement.ensureNamespace(uri: .spreadsheet)
        writeRows(to: worksheetElement)
        return document
    }

    private static func rows(in document: XMLDocument) -> [Int: XLRowStorage] {
        guard let worksheetElement = document.element(name: "worksheet"),
              let sheetDataElement = worksheetElement.elements(name: "sheetData").first
        else {
            return [:]
        }

        var rows: [Int: XLRowStorage] = [:]
        for rowElement in sheetDataElement.elements(name: "row") {
            guard let rowNumberText = rowElement.attribute(name: "r"),
                  let rowNumber = Int(rowNumberText)
            else {
                continue
            }

            rows[rowNumber] = XLRowStorage(rowElement: rowElement, rowNumber: rowNumber)
        }

        return rows
    }

    private func writeRows(to worksheetElement: XMLElement) {
        guard !rowFromNumber.isEmpty else {
            return
        }

        let sheetDataElement = sheetDataElementForWriting(in: worksheetElement)
        let sheetDataChildren = rowElementsAndOtherChildren(in: sheetDataElement)
        var rowElementFromNumber = sheetDataChildren.rowElementFromNumber
        for rowNumber in rowFromNumber.keys.sorted() {
            guard let row = rowFromNumber[rowNumber] else {
                continue
            }

            let rowElement = rowElementForWriting(
                rowNumber: rowNumber,
                in: sheetDataElement,
                rowElementFromNumber: &rowElementFromNumber
            )
            row.write(to: rowElement, rowNumber: rowNumber)
        }

        let rowElements = rowElementFromNumber.sorted { $0.key < $1.key }.map { $0.value as XMLNode }
        sheetDataElement.children = rowElements + sheetDataChildren.otherChildren
    }

    private func sheetDataElementForWriting(in worksheetElement: XMLElement) -> XMLElement {
        if let element = worksheetElement.elements(name: "sheetData").first {
            return element
        }

        let element = XMLElement(name: XMLName(name: "sheetData"))
        worksheetElement.appendChild(element)
        return element
    }

    private func rowElementForWriting(
        rowNumber: Int,
        in sheetDataElement: XMLElement,
        rowElementFromNumber: inout [Int: XMLElement]
    ) -> XMLElement {
        if let element = rowElementFromNumber[rowNumber] {
            return element
        }

        let element = XMLElement(
            name: XMLName(name: "row"),
            attributes: [
                XMLAttribute(name: XMLName(name: "r"), value: String(rowNumber)),
            ]
        )
        sheetDataElement.appendChild(element)
        rowElementFromNumber[rowNumber] = element
        return element
    }

    private func rowElementsAndOtherChildren(
        in sheetDataElement: XMLElement
    ) -> (rowElementFromNumber: [Int: XMLElement], otherChildren: [XMLNode]) {
        var rowElementFromNumber: [Int: XMLElement] = [:]
        var otherChildren: [XMLNode] = []
        for child in sheetDataElement.children {
            guard let rowElement = child as? XMLElement,
                  rowElement.name.name == "row",
                  let rowNumberText = rowElement.attribute(name: "r"),
                  let rowNumber = Int(rowNumberText)
            else {
                otherChildren.append(child)
                continue
            }

            rowElementFromNumber[rowNumber] = rowElement
        }

        return (rowElementFromNumber, otherChildren)
    }

    private func worksheetElementForWriting(in document: XMLDocument) -> XMLElement {
        if let element = document.element(name: "worksheet") {
            return element
        }

        let element = XMLElement(name: XMLName(name: "worksheet"))
        document.appendChild(element)
        return element
    }
}
