import Foundation

public final class XLCellStorage: Hashable {
    public init(value: XLCellValue) {
        self.value = value
    }

    init?(cellElement: XMLElement) {
        guard let value = Self.value(in: cellElement) else {
            return nil
        }

        self.value = value
    }

    public var value: XLCellValue

    public static func == (lhs: XLCellStorage, rhs: XLCellStorage) -> Bool {
        lhs.value == rhs.value
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(value)
    }

    func write(to cellElement: XMLElement, sharedStrings: XLSharedStringWritePlan? = nil) throws {
        cellElement.children = cellElement.children.filter { child in
            guard let element = child as? XMLElement else {
                return true
            }
            return element.name.name != "v" && element.name.name != "is"
        }

        switch value {
        case .number:
            removeCellType(in: cellElement)
            appendValueElement(to: cellElement, text: value.description)
        case .boolean:
            setCellType("b", in: cellElement)
            appendValueElement(to: cellElement, text: value.description)
        case .string:
            if let sharedStrings {
                setCellType("s", in: cellElement)
                appendValueElement(to: cellElement, text: String(try sharedStrings.index(for: value)))
            } else {
                removeCellType(in: cellElement)
                appendValueElement(to: cellElement, text: value.description)
            }
        case .error:
            setCellType("e", in: cellElement)
            appendValueElement(to: cellElement, text: value.description)
        case .opaqueSharedString:
            setCellType("s", in: cellElement)
            appendValueElement(to: cellElement, text: try valueText(sharedStrings: sharedStrings))
        }
    }

    func resolveSharedStrings(_ sharedStrings: XLSharedStringsFile) {
        value = sharedStrings.resolve(value)
    }

    func collectSharedStringValues(into collector: inout XLSharedStringCollector) {
        collector.collect(value)
    }

    private static func value(in cellElement: XMLElement) -> XLCellValue? {
        let cellType = cellElement.attribute(name: "t")
        if cellType == "inlineStr" {
            guard let inlineStringElement = cellElement.elements(name: "is").first else {
                return nil
            }
            return .string(textContent(in: inlineStringElement))
        }

        guard let valueText = valueText(in: cellElement) else {
            return nil
        }

        switch cellType {
        case nil, "n":
            if Self.isNumber(valueText) {
                return .number(valueText)
            }
            return .string(valueText)
        case "b":
            return .boolean(XLCellValue.readBool(string: valueText) ?? false)
        case "d":
            return .string(valueText)
        case "e":
            return .error(valueText)
        case "s":
            guard let sharedStringIndex = Int(valueText) else {
                return nil
            }
            return .opaqueSharedString(index: sharedStringIndex)
        case "str":
            return .string(valueText)
        default:
            return .string(valueText)
        }
    }

    private static func valueText(in cellElement: XMLElement) -> String? {
        guard let valueElement = cellElement.elements(name: "v").first else {
            return nil
        }
        return textContent(in: valueElement)
    }

    private static func textContent(in element: XMLElement) -> String {
        textContent(in: element as XMLNode)
    }

    private static func textContent(in node: XMLNode) -> String {
        if let text = node as? XMLText {
            return text.value
        }
        return node.children.map { textContent(in: $0) }.joined()
    }

    private static func isNumber(_ value: String) -> Bool {
        Double(value) != nil
    }

    private func valueText(sharedStrings: XLSharedStringWritePlan?) throws -> String {
        guard let sharedStrings else {
            return value.description
        }
        return String(try sharedStrings.index(for: value))
    }

    private func appendValueElement(to cellElement: XMLElement, text: String) {
        let valueElement = XMLElement(name: XMLName(name: "v"))
        valueElement.appendChild(XMLText(text))
        cellElement.appendChild(valueElement)
    }

    private func setCellType(_ type: String, in cellElement: XMLElement) {
        if let index = cellElement.attributes.firstIndex(where: { $0.name.prefix == nil && $0.name.name == "t" }) {
            cellElement.attributes[index].value = type
        } else {
            cellElement.attributes.append(XMLAttribute(name: XMLName(name: "t"), value: type))
        }
    }

    private func removeCellType(in cellElement: XMLElement) {
        cellElement.attributes.removeAll { $0.name.prefix == nil && $0.name.name == "t" }
    }
}
