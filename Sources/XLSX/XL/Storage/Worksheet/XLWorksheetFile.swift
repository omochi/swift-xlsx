import OrderedCollections

public final class XLWorksheetFile {
    public init() {
        self.original = nil
        self.columnByNumber = [:]
        self.rowByNumber = [:]
    }

    public init(
        columnByNumber: [Int: XLColumnStorage] = [:],
        rowByNumber: [Int: XLRowStorage]
    ) {
        self.original = nil
        self.columnByNumber = columnByNumber
        self.rowByNumber = rowByNumber
    }

    public init(
        xmlDocument: XMLDocument,
        sharedStringStorage: OrderedSet<XLSharedStringRecord>,
        styleStorage: XLStyleStorage
    ) throws {
        let rowByNumber = Self.rows(
            in: xmlDocument,
            sharedStringStorage: sharedStringStorage,
            styleStorage: styleStorage
        )

        self.original = xmlDocument
        self.columnByNumber = Self.columns(in: xmlDocument, styleStorage: styleStorage)
        self.rowByNumber = rowByNumber
    }

    public var columnByNumber: [Int: XLColumnStorage]
    public var rowByNumber: [Int: XLRowStorage]
    public var original: XMLDocument?

    public var maxColumnNumber: Int? {
        columnByNumber.keys.max()
    }

    public var maxRowNumber: Int? {
        rowByNumber.keys.max()
    }

    public var existingColumnNumbers: [Int] {
        columnByNumber.keys.sorted()
    }

    public var existingRowNumbers: [Int] {
        rowByNumber.keys.sorted()
    }

    public var existingColumnsWithNumber: [(Int, XLColumnStorage)] {
        columnByNumber.sorted { $0.key < $1.key }
    }

    public var existingRowsWithNumber: [(Int, XLRowStorage)] {
        rowByNumber.sorted { $0.key < $1.key }
    }

    public var existingColumns: [XLColumnStorage] {
        existingColumnsWithNumber.map(\.1)
    }

    public var existingRows: [XLRowStorage] {
        existingRowsWithNumber.map(\.1)
    }

    public func existingColumn(_ number: Int) -> XLColumnStorage? {
        columnByNumber[number]
    }

    public func existingRow(_ number: Int) -> XLRowStorage? {
        rowByNumber[number]
    }

    public func column(_ number: Int) -> XLColumnStorage {
        if let column = columnByNumber[number] {
            return column
        }

        let column = XLColumnStorage(width: nil)
        columnByNumber[number] = column
        return column
    }

    public func row(_ number: Int) -> XLRowStorage {
        if let row = rowByNumber[number] {
            return row
        }

        let row = XLRowStorage(cellByColumn: [:])
        rowByNumber[number] = row
        return row
    }

    public func cell(row: Int, column: Int) -> XLCellStorage {
        self.row(row).cell(column: column)
    }

    public func cell(address: XLCellAddress) -> XLCellStorage {
        cell(row: address.row, column: address.column)
    }

    public func formula(at address: XLCellAddress) -> XLFormula? {
        existingRow(address.row)?.existingCell(column: address.column)?.formula
    }

    public func xmlDocument() throws -> XMLDocument {
        try xmlDocument(sharedStringStorage: nil, styleStorage: nil)
    }

    func xmlDocument(
        sharedStringStorage: OrderedSet<XLSharedStringRecord>,
        styleStorage: XLStyleStorage
    ) throws -> XMLDocument {
        try xmlDocument(sharedStringStorage: Optional(sharedStringStorage), styleStorage: Optional(styleStorage))
    }

    private func xmlDocument(
        sharedStringStorage: OrderedSet<XLSharedStringRecord>?,
        styleStorage: XLStyleStorage?
    ) throws -> XMLDocument {
        let document = original?.clone() ?? XMLDocument()
        let worksheetElement = XMLUtils.ensureRootElement(name: "worksheet", in: document)
        worksheetElement.ensureNamespace(uri: .spreadsheet)
        try writeColumns(to: worksheetElement, styleStorage: styleStorage)
        try writeRows(
            to: worksheetElement,
            sharedStringStorage: sharedStringStorage,
            styleStorage: styleStorage
        )
        return document
    }

    public func collectSharedStrings(sharedStringStorage: inout OrderedSet<XLSharedStringRecord>) {
        let formulaSharedIndicesByDefinitionAddress = sharedFormulaIndicesByDefinitionAddress()
        for (rowNumber, row) in existingRowsWithNumber {
            row.collectSharedStrings(
                sharedStringStorage: &sharedStringStorage,
                formulaSharedIndicesByDefinitionAddress: formulaSharedIndicesByDefinitionAddress,
                rowNumber: rowNumber
            )
        }
    }

    public func collectStyle(stage: XLStyleCollectionStage, styleStorage: inout XLStyleStorage) throws {
        for column in existingColumns {
            try column.collectStyle(stage: stage, styleStorage: &styleStorage)
        }
        for row in existingRows {
            try row.collectStyle(stage: stage, styleStorage: &styleStorage)
        }
    }

    public func clone() -> XLWorksheetFile {
        let file = XLWorksheetFile(
            columnByNumber: columnByNumber.mapValues { column in
                column.clone()
            },
            rowByNumber: rowByNumber.mapValues { row in
                row.clone()
            }
        )
        file.original = original
        return file
    }

    private static func columns(
        in document: XMLDocument,
        styleStorage: XLStyleStorage
    ) -> [Int: XLColumnStorage] {
        guard let worksheetElement = document.element(name: "worksheet") else {
            return [:]
        }

        var columns: [Int: XLColumnStorage] = [:]
        for colsElement in worksheetElement.elements(name: "cols") {
            for columnElement in colsElement.elements(name: "col") {
                guard let min = XMLUtils.intAttribute(name: "min", in: columnElement),
                      let max = XMLUtils.intAttribute(name: "max", in: columnElement),
                      min <= max
                else {
                    continue
                }

                let column = XLColumnStorage(columnElement: columnElement, styleStorage: styleStorage)
                for columnNumber in min...max {
                    columns[columnNumber] = column.clone()
                }
            }
        }

        return columns
    }

    private static func rows(
        in document: XMLDocument,
        sharedStringStorage: OrderedSet<XLSharedStringRecord>,
        styleStorage: XLStyleStorage
    ) -> [Int: XLRowStorage] {
        guard let worksheetElement = document.element(name: "worksheet"),
              let sheetDataElement = worksheetElement.elements(name: "sheetData").first
        else {
            return [:]
        }

        var rows: [Int: XLRowStorage] = [:]
        let sharedFormulaDefinitionAddressByIndex = Self.sharedFormulaDefinitionAddressByIndex(
            in: sheetDataElement
        )
        for rowElement in sheetDataElement.elements(name: "row") {
            guard let rowNumberText = rowElement.attribute(name: "r"),
                  let rowNumber = Int(rowNumberText)
            else {
                continue
            }

            rows[rowNumber] = XLRowStorage(
                rowElement: rowElement,
                rowNumber: rowNumber,
                sharedStringStorage: sharedStringStorage,
                styleStorage: styleStorage,
                sharedFormulaDefinitionAddressByIndex: sharedFormulaDefinitionAddressByIndex
            )
        }

        return rows
    }

    private static func sharedFormulaDefinitionAddressByIndex(
        in sheetDataElement: XMLElement
    ) -> [Int: XLCellAddress] {
        var addressByIndex: [Int: XLCellAddress] = [:]
        for rowElement in sheetDataElement.elements(name: "row") {
            guard let rowNumberText = rowElement.attribute(name: "r"),
                  let rowNumber = Int(rowNumberText)
            else {
                continue
            }

            for cellElement in rowElement.elements(name: "c") {
                guard let addressText = cellElement.attribute(name: "r"),
                      let address = XLCellAddress(addressText),
                      address.row == rowNumber,
                      let formulaElement = cellElement.elements(name: "f").first
                else {
                    continue
                }

                let formulaRecord = XLFormulaRecord(formulaElement: formulaElement)
                guard formulaRecord.kind == .shared,
                      formulaRecord.formula != nil,
                      let sharedIndex = formulaRecord.sharedIndex
                else {
                    continue
                }

                addressByIndex[sharedIndex] = address
            }
        }

        return addressByIndex
    }

    private func writeRows(
        to worksheetElement: XMLElement,
        sharedStringStorage: OrderedSet<XLSharedStringRecord>? = nil,
        styleStorage: XLStyleStorage? = nil
    ) throws {
        guard !rowByNumber.isEmpty else {
            return
        }

        let sheetDataElement = XMLUtils.ensureChildElement(name: "sheetData", in: worksheetElement)
        let sheetDataChildren = rowElementsAndOtherChildren(in: sheetDataElement)
        var rowElementByNumber = sheetDataChildren.rowElementByNumber
        let formulaSharedIndicesByDefinitionAddress = sharedFormulaIndicesByDefinitionAddress()
        for (rowNumber, row) in existingRowsWithNumber {
            let rowElement = rowElementForWriting(
                rowNumber: rowNumber,
                in: sheetDataElement,
                rowElementByNumber: &rowElementByNumber
            )
            try row.write(
                to: rowElement,
                rowNumber: rowNumber,
                sharedStringStorage: sharedStringStorage,
                styleStorage: styleStorage,
                formulaSharedIndicesByDefinitionAddress: formulaSharedIndicesByDefinitionAddress
            )
        }

        let rowElements = rowElementByNumber.sorted { $0.key < $1.key }.map { $0.value as XMLNode }
        sheetDataElement.children = rowElements + sheetDataChildren.otherChildren
    }

    private func sharedFormulaIndicesByDefinitionAddress() -> [XLCellAddress: Int] {
        var indexByAddress: [XLCellAddress: Int] = [:]
        for (rowNumber, row) in existingRowsWithNumber {
            for (column, cell) in row.existingCellsWithColumn {
                guard case .sharedDefinition = cell.formula else {
                    continue
                }

                let address = XLCellAddress(row: rowNumber, column: column)
                indexByAddress[address] = indexByAddress.count
            }
        }

        return indexByAddress
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

    private func writeColumns(
        to worksheetElement: XMLElement,
        styleStorage: XLStyleStorage? = nil
    ) throws {
        guard !columnByNumber.isEmpty else {
            return
        }

        let colsElement = XMLUtils.ensureChildElement(
            name: "cols",
            in: worksheetElement,
            insertionIndex: {
                worksheetElement.children.firstIndex { child in
                    guard let element = child as? XMLElement else {
                        return false
                    }
                    return element.name.name == "sheetData"
                }
            }
        )

        colsElement.children = try columnWriteRanges().map { range in
            let element = XMLElement(name: XMLName(name: "col"))
            try range.fields.write(
                to: element,
                minColumnNumber: range.minColumnNumber,
                maxColumnNumber: range.maxColumnNumber,
                styleStorage: styleStorage
            )
            return element
        }
    }

    private func columnWriteRanges() -> [(minColumnNumber: Int, maxColumnNumber: Int, fields: XLColumnStorage.Fields)] {
        var ranges: [(minColumnNumber: Int, maxColumnNumber: Int, fields: XLColumnStorage.Fields)] = []

        for (columnNumber, column) in existingColumnsWithNumber {
            let fields = column.fields
            guard let lastRange = ranges.last,
                  lastRange.maxColumnNumber + 1 == columnNumber,
                  lastRange.fields == fields
            else {
                ranges.append((
                    minColumnNumber: columnNumber,
                    maxColumnNumber: columnNumber,
                    fields: fields
                ))
                continue
            }

            ranges[ranges.count - 1] = (
                minColumnNumber: lastRange.minColumnNumber,
                maxColumnNumber: columnNumber,
                fields: lastRange.fields
            )
        }

        return ranges
    }

}
