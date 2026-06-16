public struct XLCellFormat: Sendable & Hashable {
    public init(
        numberFormatID: Int? = nil,
        font: XLFont? = nil,
        fill: XLFill? = nil,
        borderID: Int? = nil,
        formatID: Int? = nil,
        applyNumberFormat: Bool = false,
        applyFont: Bool? = nil,
        applyFill: Bool = false,
        applyBorder: Bool = false,
        applyAlignment: Bool = false,
        applyProtection: Bool = false
    ) {
        self.numberFormatID = numberFormatID
        self.font = font
        self.fill = fill
        self.borderID = borderID
        self.formatID = formatID
        self.applyNumberFormat = applyNumberFormat
        self.applyFont = applyFont ?? (font != nil)
        self.applyFill = applyFill || fill != nil
        self.applyBorder = applyBorder
        self.applyAlignment = applyAlignment
        self.applyProtection = applyProtection
    }

    public init(
        record: XLCellFormatRecord,
        fonts: XLFontRecordsStorage,
        fills: XLFillsStorage
    ) {
        self.numberFormatID = record.numberFormatID
        self.font = Self.font(for: record.fontID, in: fonts)
        self.fill = Self.fill(for: record.fillID, in: fills)
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
    public var font: XLFont? = nil {
        didSet {
            applyFont = font != nil
        }
    }
    public var fill: XLFill? = nil {
        didSet {
            applyFill = fill != nil
        }
    }
    public var borderID: Int? = nil
    public var formatID: Int? = nil
    public var applyNumberFormat = false
    public var applyFont = false
    public var applyFill = false
    public var applyBorder = false
    public var applyAlignment = false
    public var applyProtection = false

    func record(fonts: XLFontRecordsStorage, fills: XLFillsStorage) throws -> XLCellFormatRecord {
        try XLCellFormatRecord(
            numberFormatID: numberFormatID,
            fontID: fontID(in: fonts),
            fillID: fillID(in: fills),
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

    private static func fill(for fillID: Int?, in fills: XLFillsStorage) -> XLFill? {
        guard let fillID,
              let record = fills.record(at: fillID)
        else {
            return nil
        }

        return record
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

    private func fillID(in fills: XLFillsStorage) throws -> Int? {
        guard let fill else {
            return nil
        }

        guard let index = fills.index(for: fill) else {
            throw OPCError.missingFillRecord
        }

        return index
    }
}
