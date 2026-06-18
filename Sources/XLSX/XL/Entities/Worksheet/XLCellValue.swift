import struct Foundation.Calendar
import struct Foundation.Date
import struct Foundation.DateComponents
import struct Foundation.TimeZone
import typealias Foundation.TimeInterval
import OrderedCollections
import XLSXXML

public enum XLCellValue: Sendable & Hashable & CustomStringConvertible {
    case number(Double)
    case boolean(Bool)
    case string(String)
    case error(String)
    case opaqueSharedString(xmlString: String)

    public var description: String {
        switch self {
        case let .number(value):
            return Self.numberString(value: value)
        case let .boolean(value):
            return Self.booleanString(value: value)
        case let .string(text):
            return text
        case let .error(value):
            return value
        case let .opaqueSharedString(xmlString):
            return xmlString
        }
    }

    public var number: Double? {
        switch self {
        case let .number(value):
            return value
        default:
            return nil
        }
    }

    public var date: Date? {
        switch self {
        case let .number(value):
            return Self.dateValue(number: value)
        default:
            return nil
        }
    }

    public var boolean: Bool? {
        switch self {
        case let .boolean(value):
            return value
        default:
            return nil
        }
    }

    public var string: String? {
        switch self {
        case let .string(value):
            return value
        default:
            return nil
        }
    }

    public var error: String? {
        switch self {
        case let .error(value):
            return value
        default:
            return nil
        }
    }

    public var opaqueSharedString: String? {
        switch self {
        case let .opaqueSharedString(xmlString):
            return xmlString
        default:
            return nil
        }
    }

    public static func date(_ value: Date) -> XLCellValue {
        .number(Self.numberValue(date: value))
    }

    public init?(
        cellElement: XMLElement,
        sharedStringStorage: OrderedSet<XLSharedStringRecord>? = nil
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
            if let value = Self.numberValue(string: valueText) {
                self = .number(value)
            } else {
                self = .string(valueText)
            }
        case "b":
            self = .boolean(Self.booleanValue(string: valueText) ?? false)
        case "d":
            self = .string(valueText)
        case "e":
            self = .error(valueText)
        case "s":
            guard let sharedStringIndex = Int(valueText) else {
                return nil
            }
            guard let sharedStringStorage,
                  sharedStringStorage.indices.contains(sharedStringIndex)
            else {
                return nil
            }
            let record = sharedStringStorage[sharedStringIndex]

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
        sharedStrings: OrderedSet<XLSharedStringRecord>? = nil
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

    public static func booleanValue(string: String) -> Bool? {
        XMLUtils.boolValue(string: string)
    }

    public static func booleanString(value: Bool) -> String {
        XMLUtils.boolString(value: value)
    }

    public static func numberValue(string: String) -> Double? {
        Double(string)
    }

    public static func numberString(value: Double) -> String {
        if let integer = Int(exactly: value) {
            return integer.description
        }

        return value.description
    }

    public static func dateValue(number: Double) -> Date {
        let adjustedNumber = number >= 60 ? number - 1 : number
        let timeInterval = (adjustedNumber - 1) * secondsPerDay
        return Date(timeInterval: timeInterval, since: excelDateOrigin)
    }

    public static func numberValue(date: Date) -> Double {
        var number = date.timeIntervalSince(excelDateOrigin) / secondsPerDay + 1
        if date >= excelLeapBugStartDate {
            number += 1
        }
        return number
    }


    private func sharedStringIndex(
        for record: XLSharedStringRecord,
        in sharedStrings: OrderedSet<XLSharedStringRecord>
    ) throws -> Int {
        guard let index = sharedStrings.firstIndex(of: record) else {
            throw OPCError.invalidSharedStringsFile
        }
        return index
    }

    private func sharedStringIndex(
        for record: XLSharedStringRecord,
        in sharedStrings: OrderedSet<XLSharedStringRecord>?
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

    private static var excelDateOrigin: Date {
        date(year: 1900, month: 1, day: 1)
    }

    private static var excelLeapBugStartDate: Date {
        date(year: 1900, month: 3, day: 1)
    }

    private static var secondsPerDay: TimeInterval {
        86_400
    }

    private static func date(year: Int, month: Int, day: Int) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar.date(from: DateComponents(
            timeZone: calendar.timeZone,
            year: year,
            month: month,
            day: day
        ))!
    }
}
