import OrderedCollections
import XLSXXML

public final class XLWorksheetFile {
    private enum FrozenPanesState {
        case original
        case modified(XLFrozenPanes?)
    }

    public init() {
        self.original = nil
        self.columnByNumber = [:]
        self.rowByNumber = [:]
        self.sheetProtection = nil
        self.dataValidations = nil
        self.mcIgnorable = ""
        self.frozenPanesState = .original
    }

    public init(
        columnByNumber: [Int: XLColumnStorage] = [:],
        rowByNumber: [Int: XLRowStorage],
        sheetProtection: XLSheetProtection? = nil,
        dataValidations: XLDataValidations? = nil,
        mcIgnorable: String? = ""
    ) {
        self.original = nil
        self.columnByNumber = columnByNumber
        self.rowByNumber = rowByNumber
        self.sheetProtection = sheetProtection
        self.dataValidations = dataValidations
        self.mcIgnorable = mcIgnorable
        self.frozenPanesState = .original
    }

    public init(
        xmlDocument: XMLDocument,
        sharedStringStorage: OrderedSet<XLText>,
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
        self.sheetProtection = Self.sheetProtection(in: xmlDocument)
        self.dataValidations = Self.dataValidations(in: xmlDocument)
        self.mcIgnorable = ""
        self.frozenPanesState = .original
    }

    public var columnByNumber: [Int: XLColumnStorage]
    public var rowByNumber: [Int: XLRowStorage]
    public var sheetProtection: XLSheetProtection?
    public var dataValidations: XLDataValidations?
    public var mcIgnorable: String?
    public var original: XMLDocument?
    private var frozenPanesState: FrozenPanesState

    public var frozenPanes: XLFrozenPanes? {
        get {
            switch frozenPanesState {
            case .original:
                return original.flatMap(Self.frozenPanes(in:))
            case .modified(let frozenPanes):
                return frozenPanes
            }
        }
        set {
            frozenPanesState = .modified(newValue)
        }
    }

    var requiresDefaultWorkbookView: Bool {
        switch frozenPanesState {
        case .original, .modified(nil): return false
        case .modified: return true
        }
    }

    public var maxColumnNumber: Int? {
        rowByNumber.values.compactMap(\.maxColumnNumber).max()
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
        sharedStringStorage: OrderedSet<XLText>,
        styleStorage: XLStyleStorage
    ) throws -> XMLDocument {
        try xmlDocument(sharedStringStorage: Optional(sharedStringStorage), styleStorage: Optional(styleStorage))
    }

    private func xmlDocument(
        sharedStringStorage: OrderedSet<XLText>?,
        styleStorage: XLStyleStorage?
    ) throws -> XMLDocument {
        let document = original?.clone() ?? XMLDocument()
        let worksheetElement = XMLUtils.ensureRootElement(name: "worksheet", in: document)
        worksheetElement.setDefaultNamespace(uri: .spreadsheet)
        configureExtensionNamespaces(in: worksheetElement)
        writeFrozenPanes(to: worksheetElement)
        try writeColumns(to: worksheetElement, styleStorage: styleStorage)
        try writeRows(
            to: worksheetElement,
            sharedStringStorage: sharedStringStorage,
            styleStorage: styleStorage
        )
        writeSheetProtection(to: worksheetElement)
        writeDataValidations(to: worksheetElement)
        return document
    }

    public func collectSharedStrings(sharedStringStorage: inout OrderedSet<XLText>) {
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
            },
            sheetProtection: sheetProtection,
            dataValidations: dataValidations,
            mcIgnorable: mcIgnorable
        )
        file.original = original
        file.frozenPanesState = frozenPanesState
        return file
    }

    private static func frozenPanes(in document: XMLDocument) -> XLFrozenPanes? {
        guard let worksheetElement = document.element(name: "worksheet"),
              let sheetViewsElement = worksheetElement.elements(name: "sheetViews").first,
              let sheetViewElement = sheetViewsElement.elements(name: "sheetView").last(where: {
                  XMLUtils.intAttribute(name: "workbookViewId", in: $0) == 0
              }),
              let paneElement = sheetViewElement.elements(name: "pane").first,
              paneElement.attribute(name: "state") == "frozen",
              let rowCount = frozenPaneCount(
                  attribute: "ySplit",
                  maximum: XLCellAddress.maxRowNumber - 1,
                  in: paneElement
              ),
              let columnCount = frozenPaneCount(
                  attribute: "xSplit",
                  maximum: XLCellAddress.maxColumnNumber - 1,
                  in: paneElement
              ),
              rowCount > 0 || columnCount > 0
        else {
            return nil
        }

        return XLFrozenPanes(rowCount: rowCount, columnCount: columnCount)
    }

    private static func frozenPaneCount(
        attribute name: String,
        maximum: Int,
        in element: XMLElement
    ) -> Int? {
        guard let string = element.attribute(name: name) else {
            return 0
        }
        guard let value = Double(string),
              value >= 0,
              value.rounded() == value,
              value <= Double(maximum)
        else {
            return nil
        }
        return Int(value)
    }

    private static func sheetProtection(in document: XMLDocument) -> XLSheetProtection? {
        guard let worksheetElement = document.element(name: "worksheet"),
              let sheetProtectionElement = worksheetElement.elements(name: "sheetProtection").first
        else {
            return nil
        }

        return XLSheetProtection(element: sheetProtectionElement)
    }

    private static func dataValidations(in document: XMLDocument) -> XLDataValidations? {
        guard let worksheetElement = document.element(name: "worksheet"),
              let dataValidationsElement = worksheetElement.elements(name: "dataValidations").first
        else {
            return nil
        }

        return XLDataValidations(xmlElement: dataValidationsElement)
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
        sharedStringStorage: OrderedSet<XLText>,
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
        sharedStringStorage: OrderedSet<XLText>? = nil,
        styleStorage: XLStyleStorage? = nil
    ) throws {
        let sheetDataElement = XMLUtils.ensureChildElement(
            name: "sheetData",
            in: worksheetElement,
            insertionIndex: {
                self.worksheetChildInsertionIndex(name: "sheetData", in: worksheetElement.children)
            }
        )
        guard !rowByNumber.isEmpty else {
            return
        }

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

    private func configureExtensionNamespaces(in worksheetElement: XMLElement) {
        let mcPrefix = worksheetElement.declareNamespace(preferredPrefix: "mc", uri: .markupCompatibility)
        worksheetElement.setAttribute(
            uncheckedPrefix: mcPrefix,
            name: "Ignorable",
            value: mcIgnorable
        )
    }

    private func writeFrozenPanes(to worksheetElement: XMLElement) {
        guard case .modified(let frozenPanes) = frozenPanesState else {
            return
        }

        guard let frozenPanes else {
            removeFrozenPanes(from: worksheetElement)
            return
        }

        let sheetViewsElement = XMLUtils.ensureChildElement(
            name: "sheetViews",
            in: worksheetElement,
            insertionIndex: {
                self.worksheetChildInsertionIndex(name: "sheetViews", in: worksheetElement.children)
            }
        )
        let sheetViewElement = mainSheetView(in: sheetViewsElement) ?? appendMainSheetView(to: sheetViewsElement)
        let topLeftCell = XLCellAddress(
            row: frozenPanes.rowCount + 1,
            column: frozenPanes.columnCount + 1
        )
        let activePane = activePane(frozenPanes: frozenPanes)

        let paneElement = XMLElement(name: XMLName(name: "pane"))
        XMLUtils.setIntAttribute(
            name: "xSplit",
            value: frozenPanes.columnCount > 0 ? frozenPanes.columnCount : nil,
            in: paneElement
        )
        XMLUtils.setIntAttribute(
            name: "ySplit",
            value: frozenPanes.rowCount > 0 ? frozenPanes.rowCount : nil,
            in: paneElement
        )
        XMLUtils.setStringAttribute(name: "topLeftCell", value: topLeftCell.description, in: paneElement)
        XMLUtils.setStringAttribute(name: "activePane", value: activePane, in: paneElement)
        XMLUtils.setStringAttribute(name: "state", value: "frozen", in: paneElement)

        let selectionElement = XMLElement(name: XMLName(name: "selection"))
        XMLUtils.setStringAttribute(name: "pane", value: activePane, in: selectionElement)
        XMLUtils.setStringAttribute(name: "activeCell", value: topLeftCell.description, in: selectionElement)
        XMLUtils.setStringAttribute(name: "sqref", value: topLeftCell.description, in: selectionElement)

        let otherChildren = sheetViewElement.children.filter { child in
            guard let element = child as? XMLElement else {
                return true
            }
            return element.name.name != "pane" && element.name.name != "selection"
        }
        sheetViewElement.children = [paneElement, selectionElement] + otherChildren
    }

    private func removeFrozenPanes(from worksheetElement: XMLElement) {
        guard let sheetViewsElement = worksheetElement.elements(name: "sheetViews").first,
              let sheetViewElement = mainSheetView(in: sheetViewsElement)
        else {
            return
        }

        let selectionElement = sheetViewElement.elements(name: "selection").last
        selectionElement?.removeAttribute(name: "pane")
        let otherChildren = sheetViewElement.children.filter { child in
            guard let element = child as? XMLElement else {
                return true
            }
            return element.name.name != "pane" && element.name.name != "selection"
        }
        sheetViewElement.children = selectionElement.map { [$0] + otherChildren } ?? otherChildren
    }

    private func mainSheetView(in sheetViewsElement: XMLElement) -> XMLElement? {
        sheetViewsElement.elements(name: "sheetView").last(where: { element in
            XMLUtils.intAttribute(name: "workbookViewId", in: element) == 0
        })
    }

    private func appendMainSheetView(to sheetViewsElement: XMLElement) -> XMLElement {
        let element = XMLElement(name: XMLName(name: "sheetView"))
        XMLUtils.setIntAttribute(name: "workbookViewId", value: 0, in: element)

        let insertionIndex = sheetViewsElement.children.firstIndex { child in
            guard let childElement = child as? XMLElement else {
                return false
            }
            return childElement.name.name == "extLst"
        } ?? sheetViewsElement.children.endIndex
        sheetViewsElement.insertChild(element, at: insertionIndex)
        return element
    }

    private func activePane(frozenPanes: XLFrozenPanes) -> String {
        if frozenPanes.rowCount > 0 && frozenPanes.columnCount > 0 {
            return "bottomRight"
        }
        if frozenPanes.rowCount > 0 {
            return "bottomLeft"
        }
        return "topRight"
    }

    private func writeSheetProtection(to worksheetElement: XMLElement) {
        var children = worksheetElement.children.filter { child in
            guard let element = child as? XMLElement else {
                return true
            }
            return element.name.name != "sheetProtection"
        }

        guard let sheetProtection else {
            worksheetElement.children = children
            return
        }

        let element = XMLElement(name: XMLName(name: "sheetProtection"))
        sheetProtection.write(to: element)
        children.insert(element, at: worksheetChildInsertionIndex(name: "sheetProtection", in: children))
        worksheetElement.children = children
    }

    private func writeDataValidations(to worksheetElement: XMLElement) {
        var children = worksheetElement.children.filter { child in
            guard let element = child as? XMLElement else {
                return true
            }
            return element.name.name != "dataValidations"
        }

        guard let dataValidations else {
            worksheetElement.children = children
            return
        }

        let element = XMLElement(name: XMLName(name: "dataValidations"))
        dataValidations.write(to: element)
        children.insert(element, at: worksheetChildInsertionIndex(name: "dataValidations", in: children))
        worksheetElement.children = children
    }

    private func worksheetChildInsertionIndex(name: String, in children: [XMLNode]) -> Int {
        guard let order = Self.worksheetChildOrderByName[name] else {
            return children.endIndex
        }

        return children.firstIndex { child in
            guard let childElement = child as? XMLElement,
                  let childOrder = Self.worksheetChildOrderByName[childElement.name.name]
            else {
                return false
            }
            return childOrder > order
        } ?? children.endIndex
    }

    private static let worksheetChildOrderNames: [String] = [
        "sheetPr",
        "dimension",
        "sheetViews",
        "sheetFormatPr",
        "cols",
        "sheetData",
        "sheetCalcPr",
        "sheetProtection",
        "protectedRanges",
        "scenarios",
        "autoFilter",
        "sortState",
        "dataConsolidate",
        "customSheetViews",
        "mergeCells",
        "phoneticPr",
        "conditionalFormatting",
        "dataValidations",
        "hyperlinks",
        "printOptions",
        "pageMargins",
        "pageSetup",
        "headerFooter",
        "rowBreaks",
        "colBreaks",
        "customProperties",
        "cellWatches",
        "ignoredErrors",
        "smartTags",
        "drawing",
        "legacyDrawing",
        "legacyDrawingHF",
        "picture",
        "oleObjects",
        "controls",
        "webPublishItems",
        "tableParts",
        "extLst",
    ]

    private static let worksheetChildOrderByName: [String: Int] = Dictionary(
        uniqueKeysWithValues: worksheetChildOrderNames.enumerated().map { nameIndex, name in
            (name, nameIndex)
        }
    )
}
