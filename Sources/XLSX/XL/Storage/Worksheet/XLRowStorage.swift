import MemberwiseInit

@MemberwiseInit(.public)
public final class XLRowStorage {
    init(
        rowElement: XMLElement,
        rowNumber: Int,
        sharedStrings: XLSharedStringsFile,
        styles: XLStylesFile
    ) {
        var cells: [Int: XLCellStorage] = [:]
        for cellElement in rowElement.elements(name: "c") {
            guard let addressText = cellElement.attribute(name: "r"),
                  let address = XLCellAddress(addressText),
                  address.row == rowNumber,
                  let cell = XLCellStorage(
                    cellElement: cellElement,
                    sharedStrings: sharedStrings,
                    styles: styles
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

    func write(
        to rowElement: XMLElement,
        rowNumber: Int,
        sharedStrings: XLSharedStringRecordsStorage? = nil,
        cellFormats: XLCellFormatRecordsStorage? = nil,
        fonts: XLFontRecordsStorage? = nil,
        fills: XLFillsStorage? = nil,
        borders: XLBordersStorage? = nil
    ) throws {
        let rowChildren = cellElementsAndOtherChildren(in: rowElement, rowNumber: rowNumber)
        var cellElementByColumn = rowChildren.cellElementByColumn
        for column in cellByColumn.keys.sorted() {
            guard let cell = cellByColumn[column] else {
                continue
            }

            let address = XLCellAddress(row: rowNumber, column: column)
            let cellElement = cellElementForWriting(
                address: address,
                in: rowElement,
                cellElementByColumn: &cellElementByColumn
            )
            try cell.write(
                to: cellElement,
                sharedStrings: sharedStrings,
                cellFormats: cellFormats,
                fonts: fonts,
                fills: fills,
                borders: borders
            )
        }

        let cellElements = cellElementByColumn.sorted { $0.key < $1.key }.map { $0.value as XMLNode }
        rowElement.children = cellElements + rowChildren.otherChildren
    }

    func collectSharedStrings(into sharedStrings: XLSharedStringRecordsStorage) {
        for column in cellByColumn.keys.sorted() {
            cellByColumn[column]?.collectSharedStrings(into: sharedStrings)
        }
    }

    func collectCellFormatStyleItems(
        fonts: XLFontRecordsStorage,
        fills: XLFillsStorage,
        borders: XLBordersStorage
    ) {
        for column in cellByColumn.keys.sorted() {
            cellByColumn[column]?.collectCellFormatStyleItems(fonts: fonts, fills: fills, borders: borders)
        }
    }

    func collectCellFormats(
        into cellFormats: XLCellFormatRecordsStorage,
        fonts: XLFontRecordsStorage,
        fills: XLFillsStorage,
        borders: XLBordersStorage
    ) throws {
        for column in cellByColumn.keys.sorted() {
            try cellByColumn[column]?.collectCellFormats(into: cellFormats, fonts: fonts, fills: fills, borders: borders)
        }
    }

    func clone() -> XLRowStorage {
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
