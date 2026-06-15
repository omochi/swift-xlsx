public final class XLRowStorage: Hashable {
    public init(cellFromColumn: [Int: XLCellStorage]) {
        self.cellFromColumn = cellFromColumn
    }

    init(rowElement: XMLElement, rowNumber: Int) {
        var cells: [Int: XLCellStorage] = [:]
        for cellElement in rowElement.elements(name: "c") {
            guard let referenceText = cellElement.attribute(name: "r"),
                  let reference = XLCellReference(referenceText),
                  reference.row == rowNumber,
                  let cell = XLCellStorage(cellElement: cellElement)
            else {
                continue
            }

            cells[reference.column] = cell
        }

        self.cellFromColumn = cells
    }

    public var cellFromColumn: [Int: XLCellStorage]

    public var maxColumnNumber: Int? {
        cellFromColumn.keys.max()
    }

    public var existingColumnNumbers: [Int] {
        cellFromColumn.keys.sorted()
    }

    public func cell(column: Int) -> XLCellStorage {
        if let cell = cellFromColumn[column] {
            return cell
        }

        let cell = XLCellStorage(value: XLCellValue(rawValue: ""))
        cellFromColumn[column] = cell
        return cell
    }

    public func existingCell(column: Int) -> XLCellStorage? {
        cellFromColumn[column]
    }

    public static func == (lhs: XLRowStorage, rhs: XLRowStorage) -> Bool {
        lhs.cellFromColumn == rhs.cellFromColumn
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(cellFromColumn)
    }

    func write(to rowElement: XMLElement, rowNumber: Int) {
        let rowChildren = cellElementsAndOtherChildren(in: rowElement, rowNumber: rowNumber)
        var cellElementFromColumn = rowChildren.cellElementFromColumn
        for column in cellFromColumn.keys.sorted() {
            guard let cell = cellFromColumn[column] else {
                continue
            }

            let reference = XLCellReference(row: rowNumber, column: column)
            let cellElement = cellElementForWriting(
                reference: reference,
                in: rowElement,
                cellElementFromColumn: &cellElementFromColumn
            )
            cell.write(to: cellElement)
        }

        let cellElements = cellElementFromColumn.sorted { $0.key < $1.key }.map { $0.value as XMLNode }
        rowElement.children = cellElements + rowChildren.otherChildren
    }

    private func cellElementForWriting(
        reference: XLCellReference,
        in rowElement: XMLElement,
        cellElementFromColumn: inout [Int: XMLElement]
    ) -> XMLElement {
        if let element = cellElementFromColumn[reference.column] {
            return element
        }

        let element = XMLElement(
            name: XMLName(name: "c"),
            attributes: [
                XMLAttribute(name: XMLName(name: "r"), value: reference.description),
            ]
        )
        rowElement.appendChild(element)
        cellElementFromColumn[reference.column] = element
        return element
    }

    private func cellElementsAndOtherChildren(
        in rowElement: XMLElement,
        rowNumber: Int
    ) -> (cellElementFromColumn: [Int: XMLElement], otherChildren: [XMLNode]) {
        var cellElementFromColumn: [Int: XMLElement] = [:]
        var otherChildren: [XMLNode] = []
        for child in rowElement.children {
            guard let cellElement = child as? XMLElement,
                  cellElement.name.name == "c",
                  let referenceText = cellElement.attribute(name: "r"),
                  let reference = XLCellReference(referenceText),
                  reference.row == rowNumber
            else {
                otherChildren.append(child)
                continue
            }

            cellElementFromColumn[reference.column] = cellElement
        }

        return (cellElementFromColumn, otherChildren)
    }
}
