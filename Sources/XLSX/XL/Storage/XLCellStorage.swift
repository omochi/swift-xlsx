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

        if cellElement.attribute(name: "t") == "s",
           let sharedStringIndex = Int(valueText)
        {
            self.value = .opaqueSharedString(index: sharedStringIndex)
        } else {
            self.value = .string(valueText)
        }
    }

    public var value: XLCellValue

    public static func == (lhs: XLCellStorage, rhs: XLCellStorage) -> Bool {
        lhs.value == rhs.value
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(value)
    }

    func write(to cellElement: XMLElement, sharedStrings: XLSharedStringWritePlan? = nil) {
        if sharedStrings != nil {
            setCellType("s", in: cellElement)
        }

        let valueElement = valueElementForWriting(in: cellElement)
        valueElement.children = []
        valueElement.appendChild(XMLText(valueText(sharedStrings: sharedStrings)))
    }

    func resolveSharedStrings(_ sharedStrings: XLSharedStringsFile) {
        value = sharedStrings.resolve(value)
    }

    func collectSharedStringValues(
        usedItems: inout Set<XLSharedStringItem>,
        orderedItems: inout [XLSharedStringItem],
        usedOpaqueIndices: inout Set<Int>
    ) {
        switch value {
        case let .string(text):
            let item = XLSharedStringItem(text: text)
            if usedItems.insert(item).inserted {
                orderedItems.append(item)
            }
        case let .opaqueSharedString(index):
            usedOpaqueIndices.insert(index)
        }
    }

    private func valueElementForWriting(in cellElement: XMLElement) -> XMLElement {
        if let element = cellElement.elements(name: "v").first {
            return element
        }

        let element = XMLElement(name: XMLName(name: "v"))
        cellElement.appendChild(element)
        return element
    }

    private func valueText(sharedStrings: XLSharedStringWritePlan?) -> String {
        guard let sharedStrings else {
            return value.rawValue
        }
        return String(sharedStrings.index(for: value))
    }

    private func setCellType(_ type: String, in cellElement: XMLElement) {
        if let index = cellElement.attributes.firstIndex(where: { $0.name.prefix == nil && $0.name.name == "t" }) {
            cellElement.attributes[index].value = type
        } else {
            cellElement.attributes.append(XMLAttribute(name: XMLName(name: "t"), value: type))
        }
    }
}
