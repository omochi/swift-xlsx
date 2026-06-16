public struct XLCellFormat: Sendable & Hashable {
    public init(
        numberFormatID: Int? = nil,
        font: XLFont? = nil,
        fill: XLFill? = nil,
        border: XLBorder? = nil,
        formatID: Int? = nil,
        applyNumberFormat: Bool = false,
        applyFont: Bool? = nil,
        applyFill: Bool = false,
        applyBorder: Bool? = nil,
        applyAlignment: Bool = false,
        applyProtection: Bool = false
    ) {
        self.numberFormatID = numberFormatID
        self.font = font
        self.fill = fill
        self.border = border
        self.formatID = formatID
        self.applyNumberFormat = applyNumberFormat
        self.applyFont = applyFont ?? (font != nil)
        self.applyFill = applyFill || fill != nil
        self.applyBorder = applyBorder ?? (border != nil)
        self.applyAlignment = applyAlignment
        self.applyProtection = applyProtection
    }

    public init(
        record: XLCellFormatRecord,
        fonts: XLFontRecordsStorage,
        fills: XLFillsStorage,
        borders: XLBordersStorage
    ) {
        self.numberFormatID = record.numberFormatID
        self.font = Self.font(for: record.fontID, in: fonts)
        self.fill = Self.fill(for: record.fillID, in: fills)
        self.border = Self.border(for: record.borderID, in: borders)
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
    public var border: XLBorder? = nil {
        didSet {
            applyBorder = border != nil
        }
    }
    public var formatID: Int? = nil
    public var applyNumberFormat = false
    public var applyFont = false
    public var applyFill = false
    public var applyBorder = false
    public var applyAlignment = false
    public var applyProtection = false

    func record(
        fonts: XLFontRecordsStorage,
        fills: XLFillsStorage,
        borders: XLBordersStorage
    ) throws -> XLCellFormatRecord {
        XLCellFormatRecord(
            numberFormatID: numberFormatID,
            fontID: try fontID(in: fonts),
            fillID: try fillID(in: fills),
            borderID: try borderID(in: borders),
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

    private static func border(for borderID: Int?, in borders: XLBordersStorage) -> XLBorder? {
        guard let borderID,
              let record = borders.record(at: borderID)
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

    private func borderID(in borders: XLBordersStorage) throws -> Int? {
        guard let border else {
            return nil
        }

        guard let index = borders.index(for: border) else {
            throw OPCError.missingBorderRecord
        }

        return index
    }
}
