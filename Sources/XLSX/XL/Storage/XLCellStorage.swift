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

    func write(to cellElement: XMLElement, sharedStrings: XLSharedStringWritePlan? = nil) throws {
        if sharedStrings != nil {
            setCellType("s", in: cellElement)
        }

        let valueElement = valueElementForWriting(in: cellElement)
        valueElement.children = []
        valueElement.appendChild(XMLText(try valueText(sharedStrings: sharedStrings)))
    }

    func resolveSharedStrings(_ sharedStrings: XLSharedStringsFile) {
        value = sharedStrings.resolve(value)
    }

    func collectSharedStringValues(into collector: inout XLSharedStringCollector) {
        collector.collect(value)
    }

    private func valueElementForWriting(in cellElement: XMLElement) -> XMLElement {
        if let element = cellElement.elements(name: "v").first {
            return element
        }

        let element = XMLElement(name: XMLName(name: "v"))
        cellElement.appendChild(element)
        return element
    }

    private func valueText(sharedStrings: XLSharedStringWritePlan?) throws -> String {
        guard let sharedStrings else {
            return value.rawValue
        }
        return String(try sharedStrings.index(for: value))
    }

    private func setCellType(_ type: String, in cellElement: XMLElement) {
        if let index = cellElement.attributes.firstIndex(where: { $0.name.prefix == nil && $0.name.name == "t" }) {
            cellElement.attributes[index].value = type
        } else {
            cellElement.attributes.append(XMLAttribute(name: XMLName(name: "t"), value: type))
        }
    }
}
