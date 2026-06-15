public final class XLCellStorage: Hashable {
    public init(value: XLCellValue) {
        self.value = value
    }

    init?(cellElement: XMLElement) {
        guard let valueElement = cellElement.elements(name: "v").first,
              let valueText = valueElement.children.compactMap({ $0 as? XMLText }).first?.value
        else {
            return nil
        }

        self.value = XLCellValue(rawValue: valueText)
    }

    public var value: XLCellValue

    public static func == (lhs: XLCellStorage, rhs: XLCellStorage) -> Bool {
        lhs.value == rhs.value
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(value)
    }

    func write(to cellElement: XMLElement) {
        let valueElement = valueElementForWriting(in: cellElement)
        valueElement.children = []
        valueElement.appendChild(XMLText(value.rawValue))
    }

    private func valueElementForWriting(in cellElement: XMLElement) -> XMLElement {
        if let element = cellElement.elements(name: "v").first {
            return element
        }

        let element = XMLElement(name: XMLName(name: "v"))
        cellElement.appendChild(element)
        return element
    }
}
