public enum XLCellValue: Sendable & Hashable & CustomStringConvertible {
    case number(String)
    case boolean(Bool)
    case string(String)
    case error(String)
    case opaqueSharedString(index: Int)

    public var description: String {
        switch self {
        case let .number(value):
            return value
        case let .boolean(value):
            return value ? "1" : "0"
        case let .string(text):
            return text
        case let .error(value):
            return value
        case let .opaqueSharedString(index):
            return String(index)
        }
    }

    public static func readBool(string: String) -> Bool? {
        if let number = Int(string) {
            return number != 0
        }

        switch string.lowercased() {
        case "true", "yes":
            return true
        case "false", "no":
            return false
        default:
            return nil
        }
    }
}

extension XLCellValue {
    init?(
        cellElement: XMLElement,
        sharedStrings: XLSharedStringsFile? = nil
    ) {
        let cellType = cellElement.attribute(name: "t")
        if cellType == "inlineStr" {
            guard let inlineStringElement = cellElement.elements(name: "is").first else {
                return nil
            }
            self = .string(Self.textContent(in: inlineStringElement))
            return
        }

        guard let valueText = Self.valueText(in: cellElement) else {
            return nil
        }

        switch cellType {
        case nil, "n":
            if Self.isNumber(valueText) {
                self = .number(valueText)
            } else {
                self = .string(valueText)
            }
        case "b":
            self = .boolean(Self.readBool(string: valueText) ?? false)
        case "d":
            self = .string(valueText)
        case "e":
            self = .error(valueText)
        case "s":
            guard let sharedStringIndex = Int(valueText) else {
                return nil
            }
            if let text = sharedStrings?.text(at: sharedStringIndex) {
                self = .string(text)
            } else {
                self = .opaqueSharedString(index: sharedStringIndex)
            }
        case "str":
            self = .string(valueText)
        default:
            self = .string(valueText)
        }
    }

    func write(
        to cellElement: XMLElement,
        sharedStringWritePlan: XLSharedStringWritePlan? = nil
    ) throws {
        switch self {
        case .number:
            removeCellType(in: cellElement)
            appendValueElement(to: cellElement, text: description)
        case .boolean:
            setCellType("b", in: cellElement)
            appendValueElement(to: cellElement, text: description)
        case .string(let text):
            if let sharedStringWritePlan {
                setCellType("s", in: cellElement)
                appendValueElement(
                    to: cellElement,
                    text: String(try sharedStringWritePlan.stringIndex(for: text))
                )
            } else {
                removeCellType(in: cellElement)
                appendValueElement(to: cellElement, text: description)
            }
        case .error:
            setCellType("e", in: cellElement)
            appendValueElement(to: cellElement, text: description)
        case .opaqueSharedString(let originalIndex):
            setCellType("s", in: cellElement)
            let index = try sharedStringWritePlan?.opaqueSharedStringIndex(for: originalIndex) ?? originalIndex
            appendValueElement(
                to: cellElement,
                text: String(index)
            )
        }
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
}
