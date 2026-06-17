import MemberwiseInit

@MemberwiseInit(.public)
public struct XLFont: Sendable & Hashable {
    public init(record: XLFontRecord) {
        self.bold = record.bold
        self.italic = record.italic
        self.strike = record.strike
        self.condense = record.condense
        self.extend = record.extend
        self.outline = record.outline
        self.shadow = record.shadow
        self.underlineXMLString = record.underlineXMLString
        self.verticalAlignmentXMLString = record.verticalAlignmentXMLString
        self.size = record.size
        self.color = record.color
        self.name = record.name
        self.familyXMLString = record.familyXMLString
        self.charsetXMLString = record.charsetXMLString
        self.schemeXMLString = record.schemeXMLString
    }

    public var bold = false
    public var italic = false
    public var strike = false
    public var condense = false
    public var extend = false
    public var outline = false
    public var shadow = false
    public var underlineXMLString: String? = nil
    public var verticalAlignmentXMLString: String? = nil
    public var size: Double? = nil
    public var color: XLColor? = nil
    public var name: String? = nil
    public var familyXMLString: String? = nil
    public var charsetXMLString: String? = nil
    public var schemeXMLString: String? = nil

    public var record: XLFontRecord {
        XLFontRecord(
            bold: bold,
            italic: italic,
            strike: strike,
            condense: condense,
            extend: extend,
            outline: outline,
            shadow: shadow,
            underlineXMLString: underlineXMLString,
            verticalAlignmentXMLString: verticalAlignmentXMLString,
            size: size,
            color: color,
            name: name,
            familyXMLString: familyXMLString,
            charsetXMLString: charsetXMLString,
            schemeXMLString: schemeXMLString
        )
    }
}
