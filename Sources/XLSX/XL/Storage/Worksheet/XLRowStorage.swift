import MemberwiseInit

@MemberwiseInit(.public)
public final class XLRowStorage {
    public init(
        rowElement: XMLElement,
        rowNumber: Int,
        sharedStrings: XLSharedStringsFile,
        styles: XLStylesFile,
        sharedFormulaDefinitionAddressByIndex: [Int: XLCellAddress] = [:]
    ) {
        var cells: [Int: XLCellStorage] = [:]
        for cellElement in rowElement.elements(name: "c") {
            guard let addressText = cellElement.attribute(name: "r"),
                  let address = XLCellAddress(addressText),
                  address.row == rowNumber,
                  let cell = XLCellStorage(
                    cellElement: cellElement,
                    sharedStrings: sharedStrings,
                    styles: styles,
                    sharedFormulaDefinitionAddressByIndex: sharedFormulaDefinitionAddressByIndex
                  )
            else {
                continue
            }

            cells[address.column] = cell
        }

        self.cellByColumn = cells
    }

    public var cellByColumn: [Int: XLCellStorage]

    public var maxColumnNumber: Int? {
        cellByColumn.keys.max()
    }

    public var existingColumnNumbers: [Int] {
        cellByColumn.keys.sorted()
    }

    public var existingCellsWithColumn: [(Int, XLCellStorage)] {
        cellByColumn.sorted { $0.key < $1.key }
    }

    public var existingCells: [XLCellStorage] {
        existingCellsWithColumn.map(\.1)
    }

    public func cell(column: Int) -> XLCellStorage {
        if let cell = cellByColumn[column] {
            return cell
        }

        let cell = XLCellStorage(value: .string(""))
        cellByColumn[column] = cell
        return cell
    }

    public func existingCell(column: Int) -> XLCellStorage? {
        cellByColumn[column]
    }

    public func write(
        to rowElement: XMLElement,
        rowNumber: Int,
        sharedStrings: XLSharedStringsFile? = nil,
        styles: XLStylesFile? = nil,
        formulaSharedIndicesByDefinitionAddress: [XLCellAddress: Int]? = nil
    ) throws {
        let rowChildren = cellElementsAndOtherChildren(in: rowElement, rowNumber: rowNumber)
        var cellElementByColumn = rowChildren.cellElementByColumn
        for (column, cell) in existingCellsWithColumn {
            let address = XLCellAddress(row: rowNumber, column: column)
            let cellElement = cellElementForWriting(
                address: address,
                in: rowElement,
                cellElementByColumn: &cellElementByColumn
            )
            try cell.write(
                to: cellElement,
                address: address,
                sharedStrings: sharedStrings,
                styles: styles,
                formulaSharedIndicesByDefinitionAddress: formulaSharedIndicesByDefinitionAddress
            )
        }

        let cellElements = cellElementByColumn.sorted { $0.key < $1.key }.map { $0.value as XMLNode }
        rowElement.children = cellElements + rowChildren.otherChildren
    }

    public func collectSharedStrings(sharedStrings: XLSharedStringsFile) {
        for cell in existingCells {
            cell.collectSharedStrings(sharedStrings: sharedStrings)
        }
    }

    public func collectSharedStrings(
        sharedStrings: XLSharedStringsFile,
        formulaSharedIndicesByDefinitionAddress: [XLCellAddress: Int],
        rowNumber: Int
    ) {
        for (column, cell) in existingCellsWithColumn {
            cell.collectSharedStrings(
                sharedStrings: sharedStrings,
                address: XLCellAddress(row: rowNumber, column: column),
                formulaSharedIndicesByDefinitionAddress: formulaSharedIndicesByDefinitionAddress
            )
        }
    }

    public func collectStyle(stage: XLStyleCollectionStage, styles: XLStylesFile) throws {
        for cell in existingCells {
            try cell.collectStyle(stage: stage, styles: styles)
        }
    }

    public func clone() -> XLRowStorage {
        XLRowStorage(
            cellByColumn: cellByColumn.mapValues { cell in
                cell.clone()
            }
        )
    }

    private func cellElementForWriting(
        address: XLCellAddress,
        in rowElement: XMLElement,
        cellElementByColumn: inout [Int: XMLElement]
    ) -> XMLElement {
        if let element = cellElementByColumn[address.column] {
            return element
        }

        let element = XMLElement(
            name: XMLName(name: "c"),
            attributes: [
                XMLAttribute(name: XMLName(name: "r"), value: address.description),
            ]
        )
        rowElement.appendChild(element)
        cellElementByColumn[address.column] = element
        return element
    }

    private func cellElementsAndOtherChildren(
        in rowElement: XMLElement,
        rowNumber: Int
    ) -> (cellElementByColumn: [Int: XMLElement], otherChildren: [XMLNode]) {
        var cellElementByColumn: [Int: XMLElement] = [:]
        var otherChildren: [XMLNode] = []
        for child in rowElement.children {
            guard let cellElement = child as? XMLElement,
                  cellElement.name.name == "c",
                  let addressText = cellElement.attribute(name: "r"),
                  let address = XLCellAddress(addressText),
                  address.row == rowNumber
            else {
                otherChildren.append(child)
                continue
            }

            cellElementByColumn[address.column] = cellElement
        }

        return (cellElementByColumn, otherChildren)
    }
}
