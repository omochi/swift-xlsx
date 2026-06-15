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
        guard let original else {
            let document = XMLDocument()
            let worksheetElement = worksheetElementForWriting(in: document)
            worksheetElement.ensureNamespace(uri: .spreadsheet)
            writeRows(to: worksheetElement)
            return document
        }

        let document = original.clone()
        let worksheetElement = worksheetElementForWriting(in: document)
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
        for rowNumber in rowFromNumber.keys.sorted() {
            guard let row = rowFromNumber[rowNumber] else {
                continue
            }

            let rowElement = rowElementForWriting(rowNumber: rowNumber, in: sheetDataElement)
            row.write(to: rowElement, rowNumber: rowNumber)
        }
    }

    private func sheetDataElementForWriting(in worksheetElement: XMLElement) -> XMLElement {
        if let element = worksheetElement.elements(name: "sheetData").first {
            return element
        }

        let element = XMLElement(name: XMLName(name: "sheetData"))
        worksheetElement.appendChild(element)
        return element
    }

    private func rowElementForWriting(rowNumber: Int, in sheetDataElement: XMLElement) -> XMLElement {
        if let element = sheetDataElement.elements(name: "row").first(where: { $0.attribute(name: "r") == String(rowNumber) }) {
            return element
        }

        let element = XMLElement(
            name: XMLName(name: "row"),
            attributes: [
                XMLAttribute(name: XMLName(name: "r"), value: String(rowNumber)),
            ]
        )
        sheetDataElement.appendChild(element)
        return element
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
