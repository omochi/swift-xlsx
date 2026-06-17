public struct XLCellFormat: Hashable {
    public init(
        numberFormat: XLNumberFormat? = nil,
        font: XLFont? = nil,
        fill: XLFill? = nil,
        border: XLBorder? = nil,
        styleFormat: XLCellStyleFormatRef? = nil,
        applyNumberFormat: Bool? = nil,
        applyFont: Bool? = nil,
        applyFill: Bool? = false,
        applyBorder: Bool? = nil,
        applyAlignment: Bool = false,
        applyProtection: Bool = false
    ) {
        self.numberFormat = numberFormat
        self.font = font
        self.fill = fill
        self.border = border
        self.styleFormat = styleFormat
        self.applyNumberFormat = applyNumberFormat ?? (self.numberFormat != nil)
        self.applyFont = applyFont ?? (font != nil)
        self.applyFill = applyFill ?? (fill != nil)
        self.applyBorder = applyBorder ?? (border != nil)
        self.applyAlignment = applyAlignment
        self.applyProtection = applyProtection
    }

    public init(
        record: XLCellFormatRecord,
        numberFormats: XLNumberFormatsStorage,
        fonts: XLFontRecordsStorage,
        fills: XLFillsStorage,
        borders: XLBordersStorage,
        cellStyleFormats: XLCellStyleFormatRefsStorage
    ) {
        self.numberFormat = Self.numberFormat(for: record.numberFormatID, in: numberFormats)
        self.font = Self.font(for: record.fontID, in: fonts)
        self.fill = Self.fill(for: record.fillID, in: fills)
        self.border = Self.border(for: record.borderID, in: borders)
        self.styleFormat = record.styleFormatID.flatMap { cellStyleFormats.record(at: $0) }
        self.applyNumberFormat = record.applyNumberFormat
        self.applyFont = record.applyFont
        self.applyFill = record.applyFill
        self.applyBorder = record.applyBorder
        self.applyAlignment = record.applyAlignment
        self.applyProtection = record.applyProtection
    }

    public var numberFormat: XLNumberFormat? = nil {
        didSet {
            applyNumberFormat = numberFormat != nil
        }
    }
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
    public var styleFormat: XLCellStyleFormatRef? = nil
    public var applyNumberFormat = false
    public var applyFont = false
    public var applyFill = false
    public var applyBorder = false
    public var applyAlignment = false
    public var applyProtection = false

    public func record(
        numberFormats: XLNumberFormatsStorage,
        fonts: XLFontRecordsStorage,
        fills: XLFillsStorage,
        borders: XLBordersStorage,
        cellStyleFormats: XLCellStyleFormatRefsStorage
    ) throws -> XLCellFormatRecord {
        XLCellFormatRecord(
            numberFormatID: try numberFormatID(in: numberFormats),
            fontID: try fontID(in: fonts),
            fillID: try fillID(in: fills),
            borderID: try borderID(in: borders),
            styleFormatID: styleFormatID(in: cellStyleFormats),
            applyNumberFormat: applyNumberFormat,
            applyFont: applyFont,
            applyFill: applyFill,
            applyBorder: applyBorder,
            applyAlignment: applyAlignment,
            applyProtection: applyProtection
        )
    }

    public func record(styles: XLStylesFile) throws -> XLCellFormatRecord {
        try record(
            numberFormats: styles.numberFormats,
            fonts: styles.fonts,
            fills: styles.fills,
            borders: styles.borders,
            cellStyleFormats: styles.cellStyleFormats
        )
    }

    public func collectStyle(stage: XLStyleCollectionStage, styles: XLStylesFile) throws {
        switch stage {
        case .numberFormats:
            if case let .format(format)? = numberFormat {
                styles.numberFormats.register(format)
            }
        case .fonts:
            if let font {
                styles.fonts.register(font.record)
            }
        case .fills:
            if let fill {
                styles.fills.register(fill)
            }
        case .borders:
            if let border {
                styles.borders.register(border)
            }
        case .cellStyleFormats:
            break
        case .cellFormats:
            try styles.cellFormats.register(self, styles: styles)
        }

        styleFormat?.collectStyle(stage: stage, styles: styles)
    }

    private static func numberFormat(
        for numberFormatID: Int?,
        in numberFormats: XLNumberFormatsStorage
    ) -> XLNumberFormat? {
        guard let numberFormatID else {
            return nil
        }

        if let format = numberFormats.format(for: numberFormatID) {
            return .format(format)
        }

        return .builtin(id: numberFormatID)
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

    private func numberFormatID(in numberFormats: XLNumberFormatsStorage) throws -> Int? {
        guard let numberFormat else {
            return nil
        }

        switch numberFormat {
        case let .builtin(id):
            return id
        case let .format(format):
            guard let id = numberFormats.id(for: format) else {
                throw OPCError.missingNumberFormatRecord
            }

            return id
        }
    }

    private func styleFormatID(in cellStyleFormats: XLCellStyleFormatRefsStorage) -> Int? {
        guard let styleFormat else {
            return nil
        }

        return cellStyleFormats.index(for: styleFormat)
    }
}
