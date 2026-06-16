import Foundation

public final class XLCellStorage {
    public init(
        value: XLCellValue,
        formatObject: XLCellFormatObject? = nil
    ) {
        self.value = value
        self.formatObject = formatObject
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
        self.formatObject = Self.formatObject(
            in: cellElement,
            styles: styles
        )
    }

    public var value: XLCellValue
    public private(set) var formatObject: XLCellFormatObject?

    public var format: XLCellFormat? {
        formatObject?.format
    }

    public func setFormat(
        _ format: XLCellFormat?,
        pool: XLCellFormatObjectPool
    ) {
        formatObject = format.map { pool.intern($0) }
    }

    func write(
        to cellElement: XMLElement,
        sharedStringWritePlan: XLSharedStringWritePlan? = nil,
        cellFormats: XLCellFormatObjectPool? = nil
    ) throws {
        writeFormat(to: cellElement, cellFormats: cellFormats)

        cellElement.children = cellElement.children.filter { child in
            guard let element = child as? XMLElement else {
                return true
            }
            return element.name.name != "v" && element.name.name != "is"
        }

        try value.write(to: cellElement, sharedStringWritePlan: sharedStringWritePlan)
    }

    func collectSharedStringValues(into collector: inout XLSharedStringCollector) {
        collector.collect(value)
    }

    func collectCellFormats(into pool: XLCellFormatObjectPool) {
        guard let formatObject else {
            return
        }

        self.formatObject = pool.intern(formatObject.record)
    }

    func clone() -> XLCellStorage {
        XLCellStorage(value: value, formatObject: formatObject)
    }

    private static func formatIndex(in cellElement: XMLElement) -> Int? {
        guard let value = cellElement.attribute(name: "s") else {
            return nil
        }
        return Int(value)
    }

    private static func formatObject(
        in cellElement: XMLElement,
        styles: XLStylesFile
    ) -> XLCellFormatObject? {
        guard let formatIndex = formatIndex(in: cellElement) else {
            return nil
        }

        return styles.cellFormats.object(at: formatIndex)
    }

    private func writeFormat(
        to cellElement: XMLElement,
        cellFormats: XLCellFormatObjectPool?
    ) {
        if let formatObject,
           let formatIndex = cellFormats?.index(for: formatObject)
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
