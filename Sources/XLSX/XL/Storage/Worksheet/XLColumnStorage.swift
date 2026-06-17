import MemberwiseInit

@MemberwiseInit(.public)
public final class XLColumnStorage {
    public init(
        columnElement: XMLElement,
        styles: XLStylesFile
    ) {
        self.width = XMLUtils.doubleAttribute(name: "width", in: columnElement)
        self.format = Self.format(in: columnElement, styles: styles)
    }

    public var width: Double?
    public var format: XLCellFormat? = nil

    public func write(
        to columnElement: XMLElement,
        columnNumber: Int,
        styles: XLStylesFile? = nil
    ) throws {
        try XLColumnWriteRecord(column: self, styles: styles).write(
            to: columnElement,
            minColumnNumber: columnNumber,
            maxColumnNumber: columnNumber
        )
    }

    public func collectStyle(stage: XLStyleCollectionStage, styles: XLStylesFile) throws {
        try format?.collectStyle(stage: stage, styles: styles)
    }

    public func clone() -> XLColumnStorage {
        XLColumnStorage(width: width, format: format)
    }

    private static func formatIndex(in columnElement: XMLElement) -> Int? {
        guard let value = columnElement.attribute(name: "style") else {
            return nil
        }
        return Int(value)
    }

    private static func format(
        in columnElement: XMLElement,
        styles: XLStylesFile
    ) -> XLCellFormat? {
        guard let formatIndex = formatIndex(in: columnElement) else {
            return nil
        }

        guard let record = styles.cellFormats.record(at: formatIndex) else {
            return nil
        }

        return XLCellFormat(
            record: record,
            numberFormats: styles.numberFormats,
            fonts: styles.fonts,
            fills: styles.fills,
            borders: styles.borders,
            cellStyleFormats: styles.cellStyleFormats
        )
    }

}
