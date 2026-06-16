import Foundation

public final class XLCellStorage {
    public init(
        value: XLCellValue,
        format: XLCellFormat? = nil
    ) {
        self.value = value
        self.format = format
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
        self.format = Self.format(
            in: cellElement,
            styles: styles
        )
    }

    public var value: XLCellValue
    public var format: XLCellFormat?

    func write(
        to cellElement: XMLElement,
        sharedStrings: XLSharedStringRecordsStorage? = nil,
        cellFormats: XLCellFormatRecordsStorage? = nil,
        fonts: XLFontRecordsStorage? = nil,
        fills: XLFillsStorage? = nil,
        borders: XLBordersStorage? = nil
    ) throws {
        try writeFormat(to: cellElement, cellFormats: cellFormats, fonts: fonts, fills: fills, borders: borders)

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

    func collectCellFormatStyleItems(
        fonts: XLFontRecordsStorage,
        fills: XLFillsStorage,
        borders: XLBordersStorage
    ) {
        if let font = format?.font {
            fonts.register(font.record)
        }
        if let fill = format?.fill {
            fills.register(fill)
        }
        if let border = format?.border {
            borders.register(border)
        }
    }

    func collectCellFormats(
        into cellFormats: XLCellFormatRecordsStorage,
        fonts: XLFontRecordsStorage,
        fills: XLFillsStorage,
        borders: XLBordersStorage
    ) throws {
        guard let format else {
            return
        }

        try cellFormats.register(format, fonts: fonts, fills: fills, borders: borders)
    }

    func clone() -> XLCellStorage {
        XLCellStorage(value: value, format: format)
    }

    private static func formatIndex(in cellElement: XMLElement) -> Int? {
        guard let value = cellElement.attribute(name: "s") else {
            return nil
        }
        return Int(value)
    }

    private static func format(
        in cellElement: XMLElement,
        styles: XLStylesFile
    ) -> XLCellFormat? {
        guard let formatIndex = formatIndex(in: cellElement) else {
            return nil
        }

        guard let record = styles.cellFormats.record(at: formatIndex) else {
            return nil
        }

        return XLCellFormat(record: record, fonts: styles.fonts, fills: styles.fills, borders: styles.borders)
    }

    private func writeFormat(
        to cellElement: XMLElement,
        cellFormats: XLCellFormatRecordsStorage?,
        fonts: XLFontRecordsStorage?,
        fills: XLFillsStorage?,
        borders: XLBordersStorage?
    ) throws {
        guard let format,
              let fonts,
              let fills,
              let borders
        else {
            removeAttribute(name: "s", in: cellElement)
            return
        }

        let formatRecord = try format.record(fonts: fonts, fills: fills, borders: borders)
        if let formatIndex = cellFormats?.index(for: formatRecord) {
            cellElement.setAttribute(name: "s", value: String(formatIndex))
        } else {
            removeAttribute(name: "s", in: cellElement)
        }
    }

    private func removeAttribute(name: String, in cellElement: XMLElement) {
        cellElement.attributes.removeAll { $0.name.prefix == nil && $0.name.name == name }
    }
}
