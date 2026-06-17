public enum XLCellValue: Sendable & Hashable & CustomStringConvertible {
    case number(String)
    case boolean(Bool)
    case string(String)
    case error(String)
    case opaqueSharedString(xmlString: String)

    public var description: String {
        switch self {
        case let .number(value):
            return value
        case let .boolean(value):
            return XMLUtils.boolString(value: value)
        case let .string(text):
            return text
        case let .error(value):
            return value
        case let .opaqueSharedString(xmlString):
            return xmlString
        }
    }

    public static func readBool(string: String) -> Bool? {
        XMLUtils.boolValue(string: string)
    }
}

extension XLCellValue {
    public init?(
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
            guard let record = sharedStrings?.record(at: sharedStringIndex) else {
                return nil
            }

            if case let .text(text) = record {
                self = .string(text)
            } else if case let .opaque(xmlString) = record {
                self = .opaqueSharedString(xmlString: xmlString)
            } else {
                return nil
            }
        case "str":
            self = .string(valueText)
        default:
            self = .string(valueText)
        }
    }

    public func write(
        to cellElement: XMLElement,
        sharedStrings: XLSharedStringRecordsStorage? = nil
    ) throws {
        switch self {
        case .number:
            removeCellType(in: cellElement)
            appendValueElement(to: cellElement, text: description)
        case .boolean:
            setCellType("b", in: cellElement)
            appendValueElement(to: cellElement, text: description)
        case .string(let text):
            if let sharedStrings {
                setCellType("s", in: cellElement)
                appendValueElement(
                    to: cellElement,
                    text: String(try sharedStringIndex(for: .text(text), in: sharedStrings))
                )
            } else {
                removeCellType(in: cellElement)
                appendValueElement(to: cellElement, text: description)
            }
        case .error:
            setCellType("e", in: cellElement)
            appendValueElement(to: cellElement, text: description)
        case .opaqueSharedString(let xmlString):
            setCellType("s", in: cellElement)
            let index = try sharedStringIndex(
                for: .opaque(xmlString: xmlString),
                in: sharedStrings
            )
            appendValueElement(
                to: cellElement,
                text: String(index)
            )
        }
    }

    private func sharedStringIndex(
        for record: XLSharedStringRecord,
        in sharedStrings: XLSharedStringRecordsStorage
    ) throws -> Int {
        guard let index = sharedStrings.index(for: record) else {
            throw OPCError.invalidSharedStringsFile
        }
        return index
    }

    private func sharedStringIndex(
        for record: XLSharedStringRecord,
        in sharedStrings: XLSharedStringRecordsStorage?
    ) throws -> Int {
        guard let sharedStrings else {
            throw OPCError.invalidSharedStringsFile
        }
        return try sharedStringIndex(for: record, in: sharedStrings)
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
