public final class XLWorksheetFile: OPCXMLFile {
    public init() {
        self.original = nil
        self.rowByNumber = [:]
    }

    public init(rowByNumber: [Int: XLRowStorage]) {
        self.original = nil
        self.rowByNumber = rowByNumber
    }

    public init(xmlDocument: XMLDocument) throws {
        self.original = xmlDocument
        self.rowByNumber = Self.rows(in: xmlDocument)
    }

    public var original: XMLDocument?
    public var rowByNumber: [Int: XLRowStorage]

    public var maxRowNumber: Int? {
        rowByNumber.keys.max()
    }

    public var existingRowNumbers: [Int] {
        rowByNumber.keys.sorted()
    }

    public func row(_ number: Int) -> XLRowStorage {
        if let row = rowByNumber[number] {
            return row
        }

        let row = XLRowStorage(cellByColumn: [:])
        rowByNumber[number] = row
        return row
    }

    public func existingRow(_ number: Int) -> XLRowStorage? {
        rowByNumber[number]
    }

    public func cell(row: Int, column: Int) -> XLCellStorage {
        self.row(row).cell(column: column)
    }

    public func cell(reference: XLCellReference) -> XLCellStorage {
        cell(row: reference.row, column: reference.column)
    }

    public func xmlDocument() -> XMLDocument {
        xmlDocument(sharedStrings: nil)
    }

    func xmlDocument(sharedStrings: XLSharedStringWritePlan?) -> XMLDocument {
        let document = original?.clone() ?? XMLDocument()
        let worksheetElement = worksheetElementForWriting(in: document)
        worksheetElement.ensureNamespace(uri: .spreadsheet)
        writeRows(to: worksheetElement, sharedStrings: sharedStrings)
        return document
    }

    func resolveSharedStrings(_ sharedStrings: XLSharedStringsFile) {
        for row in rowByNumber.values {
            row.resolveSharedStrings(sharedStrings)
        }
    }

    func collectSharedStringValues(
        usedItems: inout Set<XLSharedStringItem>,
        orderedItems: inout [XLSharedStringItem],
        usedOpaqueIndices: inout Set<Int>
    ) {
        for rowNumber in rowByNumber.keys.sorted() {
            rowByNumber[rowNumber]?.collectSharedStringValues(
                usedItems: &usedItems,
                orderedItems: &orderedItems,
                usedOpaqueIndices: &usedOpaqueIndices
            )
        }
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

    private func writeRows(
        to worksheetElement: XMLElement,
        sharedStrings: XLSharedStringWritePlan? = nil
    ) {
        guard !rowByNumber.isEmpty else {
            return
        }

        let sheetDataElement = sheetDataElementForWriting(in: worksheetElement)
        let sheetDataChildren = rowElementsAndOtherChildren(in: sheetDataElement)
        var rowElementByNumber = sheetDataChildren.rowElementByNumber
        for rowNumber in rowByNumber.keys.sorted() {
            guard let row = rowByNumber[rowNumber] else {
                continue
            }

            let rowElement = rowElementForWriting(
                rowNumber: rowNumber,
                in: sheetDataElement,
                rowElementByNumber: &rowElementByNumber
            )
            row.write(to: rowElement, rowNumber: rowNumber, sharedStrings: sharedStrings)
        }

        let rowElements = rowElementByNumber.sorted { $0.key < $1.key }.map { $0.value as XMLNode }
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
        rowElementByNumber: inout [Int: XMLElement]
    ) -> XMLElement {
        if let element = rowElementByNumber[rowNumber] {
            return element
        }

        let element = XMLElement(
            name: XMLName(name: "row"),
            attributes: [
                XMLAttribute(name: XMLName(name: "r"), value: String(rowNumber)),
            ]
        )
        sheetDataElement.appendChild(element)
        rowElementByNumber[rowNumber] = element
        return element
    }

    private func rowElementsAndOtherChildren(
        in sheetDataElement: XMLElement
    ) -> (rowElementByNumber: [Int: XMLElement], otherChildren: [XMLNode]) {
        var rowElementByNumber: [Int: XMLElement] = [:]
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

            rowElementByNumber[rowNumber] = rowElement
        }

        return (rowElementByNumber, otherChildren)
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
