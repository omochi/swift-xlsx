import MemberwiseInit

@MemberwiseInit(.public)
public struct XLCellFormat: Sendable & Hashable {
    public init(record: XLCellFormatRecord) {
        self.numberFormatID = record.numberFormatID
        self.fontID = record.fontID
        self.fillID = record.fillID
        self.borderID = record.borderID
        self.formatID = record.formatID
        self.applyNumberFormat = record.applyNumberFormat
        self.applyFont = record.applyFont
        self.applyFill = record.applyFill
        self.applyBorder = record.applyBorder
        self.applyAlignment = record.applyAlignment
        self.applyProtection = record.applyProtection
    }

    public var numberFormatID: Int? = nil
    public var fontID: Int? = nil
    public var fillID: Int? = nil
    public var borderID: Int? = nil
    public var formatID: Int? = nil
    public var applyNumberFormat = false
    public var applyFont = false
    public var applyFill = false
    public var applyBorder = false
    public var applyAlignment = false
    public var applyProtection = false

    var record: XLCellFormatRecord {
        XLCellFormatRecord(
            numberFormatID: numberFormatID,
            fontID: fontID,
            fillID: fillID,
            borderID: borderID,
            formatID: formatID,
            applyNumberFormat: applyNumberFormat,
            applyFont: applyFont,
            applyFill: applyFill,
            applyBorder: applyBorder,
            applyAlignment: applyAlignment,
            applyProtection: applyProtection
        )
    }
}
