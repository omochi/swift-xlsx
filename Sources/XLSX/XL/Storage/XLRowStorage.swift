public final class XLRowStorage: Hashable {
    public init(cellByColumn: [Int: XLCellStorage]) {
        self.cellByColumn = cellByColumn
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

        self.cellByColumn = cells
    }

    public var cellByColumn: [Int: XLCellStorage]

    public var maxColumnNumber: Int? {
        cellByColumn.keys.max()
    }

    public var existingColumnNumbers: [Int] {
        cellByColumn.keys.sorted()
    }

    public func cell(column: Int) -> XLCellStorage {
        if let cell = cellByColumn[column] {
            return cell
        }

        let cell = XLCellStorage(value: XLCellValue(rawValue: ""))
        cellByColumn[column] = cell
        return cell
    }

    public func existingCell(column: Int) -> XLCellStorage? {
        cellByColumn[column]
    }

    public static func == (lhs: XLRowStorage, rhs: XLRowStorage) -> Bool {
        lhs.cellByColumn == rhs.cellByColumn
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(cellByColumn)
    }

    func write(
        to rowElement: XMLElement,
        rowNumber: Int,
        sharedStrings: XLSharedStringWritePlan? = nil
    ) throws {
        let rowChildren = cellElementsAndOtherChildren(in: rowElement, rowNumber: rowNumber)
        var cellElementByColumn = rowChildren.cellElementByColumn
        for column in cellByColumn.keys.sorted() {
            guard let cell = cellByColumn[column] else {
                continue
            }

            let reference = XLCellReference(row: rowNumber, column: column)
            let cellElement = cellElementForWriting(
                reference: reference,
                in: rowElement,
                cellElementByColumn: &cellElementByColumn
            )
            try cell.write(to: cellElement, sharedStrings: sharedStrings)
        }

        let cellElements = cellElementByColumn.sorted { $0.key < $1.key }.map { $0.value as XMLNode }
        rowElement.children = cellElements + rowChildren.otherChildren
    }

    func resolveSharedStrings(_ sharedStrings: XLSharedStringsFile) {
        for cell in cellByColumn.values {
            cell.resolveSharedStrings(sharedStrings)
        }
    }

    func collectSharedStringValues(into collector: inout XLSharedStringCollector) {
        for column in cellByColumn.keys.sorted() {
            cellByColumn[column]?.collectSharedStringValues(into: &collector)
        }
    }

    private func cellElementForWriting(
        reference: XLCellReference,
        in rowElement: XMLElement,
        cellElementByColumn: inout [Int: XMLElement]
    ) -> XMLElement {
        if let element = cellElementByColumn[reference.column] {
            return element
        }

        let element = XMLElement(
            name: XMLName(name: "c"),
            attributes: [
                XMLAttribute(name: XMLName(name: "r"), value: reference.description),
            ]
        )
        rowElement.appendChild(element)
        cellElementByColumn[reference.column] = element
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
                  let referenceText = cellElement.attribute(name: "r"),
                  let reference = XLCellReference(referenceText),
                  reference.row == rowNumber
            else {
                otherChildren.append(child)
                continue
            }

            cellElementByColumn[reference.column] = cellElement
        }

        return (cellElementByColumn, otherChildren)
    }
}
