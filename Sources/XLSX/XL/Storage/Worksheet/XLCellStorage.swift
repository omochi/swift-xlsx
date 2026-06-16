import MemberwiseInit
import Foundation

@MemberwiseInit(.public)
public final class XLCellStorage {
    init?(cellElement: XMLElement) {
        guard let value = Self.value(in: cellElement) else {
            return nil
        }

        self.value = value
        self.formatIndex = Self.formatIndex(in: cellElement)
    }

    public var value: XLCellValue
    public var formatIndex: Int? = nil

    func write(
        to cellElement: XMLElement,
        sharedStringWritePlan: XLSharedStringWritePlan? = nil
    ) throws {
        writeFormatIndex(to: cellElement)

        cellElement.children = cellElement.children.filter { child in
            guard let element = child as? XMLElement else {
                return true
            }
            return element.name.name != "v" && element.name.name != "is"
        }

        try value.write(to: cellElement, sharedStringWritePlan: sharedStringWritePlan)
    }

    func resolveSharedStrings(_ sharedStrings: XLSharedStringsFile) {
        value = sharedStrings.resolve(value)
    }

    func collectSharedStringValues(into collector: inout XLSharedStringCollector) {
        collector.collect(value)
    }

    func clone() -> XLCellStorage {
        XLCellStorage(value: value, formatIndex: formatIndex)
    }

    private static func formatIndex(in cellElement: XMLElement) -> Int? {
        guard let value = cellElement.attribute(name: "s") else {
            return nil
        }
        return Int(value)
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

    private func writeFormatIndex(to cellElement: XMLElement) {
        if let formatIndex {
            cellElement.setAttribute(name: "s", value: String(formatIndex))
        } else {
            removeAttribute(name: "s", in: cellElement)
        }
    }

    private func removeAttribute(name: String, in cellElement: XMLElement) {
        cellElement.attributes.removeAll { $0.name.prefix == nil && $0.name.name == name }
    }
}
