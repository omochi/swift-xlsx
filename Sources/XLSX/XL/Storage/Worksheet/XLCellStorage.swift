import Foundation

public final class XLCellStorage {
    public init(
        value: XLCellValue,
        formatRecord: XLCellFormatRecord? = nil
    ) {
        self.value = value
        self.formatRecord = formatRecord
    }

    init?(
        cellElement: XMLElement,
        sharedStrings: XLSharedStringsFile,
        styles: XLStylesFile
    ) {
        guard let value = XLCellValue(
            cellElement: cellElement,
            sharedStrings: sharedStrings
        ) else {
            return nil
        }

        self.value = value
        self.formatRecord = Self.formatRecord(
            in: cellElement,
            styles: styles
        )
    }

    public var value: XLCellValue
    public private(set) var formatRecord: XLCellFormatRecord?

    public var format: XLCellFormat? {
        formatRecord.map(XLCellFormat.init(record:))
    }

    public func setFormat(
        _ format: XLCellFormat?,
        cellFormats: XLCellFormatRecordsStorage
    ) {
        formatRecord = format?.record
        if let formatRecord {
            cellFormats.register(formatRecord)
        }
    }

    func write(
        to cellElement: XMLElement,
        sharedStrings: XLSharedStringRecordsStorage? = nil,
        cellFormats: XLCellFormatRecordsStorage? = nil
    ) throws {
        writeFormat(to: cellElement, cellFormats: cellFormats)

        cellElement.children = cellElement.children.filter { child in
            guard let element = child as? XMLElement else {
                return true
            }
            return element.name.name != "v" && element.name.name != "is"
        }

        try value.write(to: cellElement, sharedStrings: sharedStrings)
    }

    func collectSharedStrings(into sharedStrings: XLSharedStringRecordsStorage) {
        switch value {
        case let .string(text):
            sharedStrings.register(text)
        case let .opaqueSharedString(xmlString):
            sharedStrings.register(.opaque(xmlString: xmlString))
        case .number, .boolean, .error:
            break
        }
    }

    func collectCellFormats(into cellFormats: XLCellFormatRecordsStorage) {
        guard let formatRecord else {
            return
        }

        cellFormats.register(formatRecord)
    }

    func clone() -> XLCellStorage {
        XLCellStorage(value: value, formatRecord: formatRecord)
    }

    private static func formatIndex(in cellElement: XMLElement) -> Int? {
        guard let value = cellElement.attribute(name: "s") else {
            return nil
        }
        return Int(value)
    }

    private static func formatRecord(
        in cellElement: XMLElement,
        styles: XLStylesFile
    ) -> XLCellFormatRecord? {
        guard let formatIndex = formatIndex(in: cellElement) else {
            return nil
        }

        return styles.cellFormats.record(at: formatIndex)
    }

    private func writeFormat(
        to cellElement: XMLElement,
        cellFormats: XLCellFormatRecordsStorage?
    ) {
        if let formatRecord,
           let formatIndex = cellFormats?.index(for: formatRecord)
        {
            cellElement.setAttribute(name: "s", value: String(formatIndex))
        } else {
            removeAttribute(name: "s", in: cellElement)
        }
    }

    private func removeAttribute(name: String, in cellElement: XMLElement) {
        cellElement.attributes.removeAll { $0.name.prefix == nil && $0.name.name == name }
    }
}
