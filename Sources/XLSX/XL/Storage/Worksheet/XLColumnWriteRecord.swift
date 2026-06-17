struct XLColumnWriteRecord: Hashable {
    init(
        column: XLColumnStorage,
        styles: XLStylesFile?
    ) throws {
        self.width = column.width
        self.formatIndex = try Self.formatIndex(format: column.format, styles: styles)
    }

    var width: Double?
    var formatIndex: Int?

    func write(
        to columnElement: XMLElement,
        minColumnNumber: Int,
        maxColumnNumber: Int
    ) {
        XMLUtils.setIntAttribute(name: "min", value: minColumnNumber, in: columnElement)
        XMLUtils.setIntAttribute(name: "max", value: maxColumnNumber, in: columnElement)
        XMLUtils.setDoubleAttribute(name: "width", value: width, in: columnElement)
        XMLUtils.setBoolAttribute(name: "customWidth", value: width == nil ? nil : true, in: columnElement)
        columnElement.setAttribute(name: "style", value: formatIndex.map(String.init))
    }

    private static func formatIndex(
        format: XLCellFormat?,
        styles: XLStylesFile?
    ) throws -> Int? {
        guard let format, let styles else {
            return nil
        }

        let formatRecord = try format.record(styles: styles)
        return styles.cellFormats.index(for: formatRecord)
    }
}
