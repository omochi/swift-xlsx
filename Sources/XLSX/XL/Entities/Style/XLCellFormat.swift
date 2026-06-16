import MemberwiseInit

@MemberwiseInit(.public)
public struct XLCellFormat: Sendable & Hashable {
    public init(
        record: XLCellFormatRecord,
        fonts: XLFontRecordsStorage
    ) {
        self.numberFormatID = record.numberFormatID
        self.font = Self.font(for: record.fontID, in: fonts)
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
    public var font: XLFont? = nil
    public var fillID: Int? = nil
    public var borderID: Int? = nil
    public var formatID: Int? = nil
    public var applyNumberFormat = false
    public var applyFont = false
    public var applyFill = false
    public var applyBorder = false
    public var applyAlignment = false
    public var applyProtection = false

    func record(fonts: XLFontRecordsStorage) throws -> XLCellFormatRecord {
        try XLCellFormatRecord(
            numberFormatID: numberFormatID,
            fontID: fontID(in: fonts),
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

    private static func font(for fontID: Int?, in fonts: XLFontRecordsStorage) -> XLFont? {
        guard let fontID,
              let record = fonts.record(at: fontID)
        else {
            return nil
        }

        return XLFont(record: record)
    }

    private func fontID(in fonts: XLFontRecordsStorage) throws -> Int? {
        guard let font else {
            return nil
        }

        guard let index = fonts.index(for: font.record) else {
            throw OPCError.missingFontRecord
        }

        return index
    }
}
