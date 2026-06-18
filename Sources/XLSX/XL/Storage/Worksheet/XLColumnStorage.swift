import MemberwiseInit

@MemberwiseInit(.public)
public final class XLColumnStorage {
    @MemberwiseInit(.public)
    public struct Fields: Hashable {
        init(
            columnElement: XMLElement,
            styles: XLStylesFile
        ) {
            self.width = XMLUtils.doubleAttribute(name: "width", in: columnElement)
            self.format = Self.format(in: columnElement, styles: styles)
            self.customWidth = XMLUtils.boolAttribute(name: "customWidth", in: columnElement, defaultValue: nil)
            self.hidden = XMLUtils.boolAttribute(name: "hidden", in: columnElement, defaultValue: nil)
            self.bestFit = XMLUtils.boolAttribute(name: "bestFit", in: columnElement, defaultValue: nil)
            self.outlineLevel = XMLUtils.intAttribute(name: "outlineLevel", in: columnElement)
            self.collapsed = XMLUtils.boolAttribute(name: "collapsed", in: columnElement, defaultValue: nil)
            self.phonetic = XMLUtils.boolAttribute(name: "phonetic", in: columnElement, defaultValue: nil)
        }

        public var width: Double?
        public var format: XLCellFormat? = nil
        public var customWidth: Bool? = nil
        public var hidden: Bool? = nil
        public var bestFit: Bool? = nil
        public var outlineLevel: Int? = nil
        public var collapsed: Bool? = nil
        public var phonetic: Bool? = nil

        func write(
            to columnElement: XMLElement,
            minColumnNumber: Int,
            maxColumnNumber: Int,
            styles: XLStylesFile?
        ) throws {
            XMLUtils.setIntAttribute(name: "min", value: minColumnNumber, in: columnElement)
            XMLUtils.setIntAttribute(name: "max", value: maxColumnNumber, in: columnElement)
            XMLUtils.setDoubleAttribute(name: "width", value: width, in: columnElement)
            XMLUtils.setBoolAttribute(name: "customWidth", value: writeCustomWidth, in: columnElement)
            columnElement.setAttribute(name: "style", value: try formatIndex(styles: styles).map(String.init))
            XMLUtils.setBoolAttribute(name: "hidden", value: hidden, in: columnElement)
            XMLUtils.setBoolAttribute(name: "bestFit", value: bestFit, in: columnElement)
            XMLUtils.setIntAttribute(name: "outlineLevel", value: outlineLevel, in: columnElement)
            XMLUtils.setBoolAttribute(name: "collapsed", value: collapsed, in: columnElement)
            XMLUtils.setBoolAttribute(name: "phonetic", value: phonetic, in: columnElement)
        }

        private var writeCustomWidth: Bool? {
            customWidth ?? (width == nil ? nil : true)
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

        private func formatIndex(styles: XLStylesFile?) throws -> Int? {
            guard let format, let styles else {
                return nil
            }

            let formatRecord = try format.record(styles: styles)
            return styles.cellFormats.index(for: formatRecord)
        }
    }

    public init(
        width: Double?,
        format: XLCellFormat? = nil,
        customWidth: Bool? = nil,
        hidden: Bool? = nil,
        bestFit: Bool? = nil,
        outlineLevel: Int? = nil,
        collapsed: Bool? = nil,
        phonetic: Bool? = nil
    ) {
        self.fields = Fields(
            width: width,
            format: format,
            customWidth: customWidth,
            hidden: hidden,
            bestFit: bestFit,
            outlineLevel: outlineLevel,
            collapsed: collapsed,
            phonetic: phonetic
        )
    }

    public init(
        columnElement: XMLElement,
        styles: XLStylesFile
    ) {
        self.fields = Fields(columnElement: columnElement, styles: styles)
    }

    public var fields: Fields

    public var width: Double? {
        get { fields.width }
        set { fields.width = newValue }
    }

    public var format: XLCellFormat? {
        get { fields.format }
        set { fields.format = newValue }
    }

    public var customWidth: Bool? {
        get { fields.customWidth }
        set { fields.customWidth = newValue }
    }

    public var hidden: Bool? {
        get { fields.hidden }
        set { fields.hidden = newValue }
    }

    public var bestFit: Bool? {
        get { fields.bestFit }
        set { fields.bestFit = newValue }
    }

    public var outlineLevel: Int? {
        get { fields.outlineLevel }
        set { fields.outlineLevel = newValue }
    }

    public var collapsed: Bool? {
        get { fields.collapsed }
        set { fields.collapsed = newValue }
    }

    public var phonetic: Bool? {
        get { fields.phonetic }
        set { fields.phonetic = newValue }
    }

    public func write(
        to columnElement: XMLElement,
        columnNumber: Int,
        styles: XLStylesFile? = nil
    ) throws {
        try fields.write(
            to: columnElement,
            minColumnNumber: columnNumber,
            maxColumnNumber: columnNumber,
            styles: styles
        )
    }

    public func collectStyle(stage: XLStyleCollectionStage, styles: XLStylesFile) throws {
        try format?.collectStyle(stage: stage, styles: styles)
    }

    public func clone() -> XLColumnStorage {
        XLColumnStorage(
            width: width,
            format: format,
            customWidth: customWidth,
            hidden: hidden,
            bestFit: bestFit,
            outlineLevel: outlineLevel,
            collapsed: collapsed,
            phonetic: phonetic
        )
    }
}
