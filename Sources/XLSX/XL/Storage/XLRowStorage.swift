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
        for column in cellFromColumn.keys.sorted() {
            guard let cell = cellFromColumn[column] else {
                continue
            }

            let reference = XLCellReference(row: rowNumber, column: column)
            let cellElement = cellElementForWriting(reference: reference, in: rowElement)
            cell.write(to: cellElement)
        }
    }

    private func cellElementForWriting(reference: XLCellReference, in rowElement: XMLElement) -> XMLElement {
        if let element = rowElement.elements(name: "c").first(where: { $0.attribute(name: "r") == reference.description }) {
            return element
        }

        let element = XMLElement(
            name: XMLName(name: "c"),
            attributes: [
                XMLAttribute(name: XMLName(name: "r"), value: reference.description),
            ]
        )
        rowElement.appendChild(element)
        return element
    }
}
