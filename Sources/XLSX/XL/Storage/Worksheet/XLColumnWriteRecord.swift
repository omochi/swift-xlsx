struct XLColumnWriteRecord: Hashable {
    init(
        column: XLColumnStorage,
        styles: XLStylesFile?
    ) throws {
        self.width = column.width
        self.formatIndex = try Self.formatIndex(format: column.format, styles: styles)
        self.customWidth = column.customWidth ?? (column.width == nil ? nil : true)
        self.hidden = column.hidden
        self.bestFit = column.bestFit
        self.outlineLevel = column.outlineLevel
        self.collapsed = column.collapsed
        self.phonetic = column.phonetic
    }

    var width: Double?
    var formatIndex: Int?
    var customWidth: Bool?
    var hidden: Bool?
    var bestFit: Bool?
    var outlineLevel: Int?
    var collapsed: Bool?
    var phonetic: Bool?

    func write(
        to columnElement: XMLElement,
        minColumnNumber: Int,
        maxColumnNumber: Int
    ) {
        XMLUtils.setIntAttribute(name: "min", value: minColumnNumber, in: columnElement)
        XMLUtils.setIntAttribute(name: "max", value: maxColumnNumber, in: columnElement)
        XMLUtils.setDoubleAttribute(name: "width", value: width, in: columnElement)
        XMLUtils.setBoolAttribute(name: "customWidth", value: customWidth, in: columnElement)
        columnElement.setAttribute(name: "style", value: formatIndex.map(String.init))
        XMLUtils.setBoolAttribute(name: "hidden", value: hidden, in: columnElement)
        XMLUtils.setBoolAttribute(name: "bestFit", value: bestFit, in: columnElement)
        XMLUtils.setIntAttribute(name: "outlineLevel", value: outlineLevel, in: columnElement)
        XMLUtils.setBoolAttribute(name: "collapsed", value: collapsed, in: columnElement)
        XMLUtils.setBoolAttribute(name: "phonetic", value: phonetic, in: columnElement)
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
