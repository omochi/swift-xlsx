import OrderedCollections

public struct XLCellFormat: Hashable {
    public init(
        numberFormat: XLNumberFormat? = nil,
        font: XLFont? = nil,
        fill: XLFill? = nil,
        border: XLBorder? = nil,
        styleFormat: XLCellStyleFormatRef? = nil,
        protection: XLCellFormatProtection? = nil,
        applyNumberFormat: Bool? = nil,
        applyFont: Bool? = nil,
        applyFill: Bool? = false,
        applyBorder: Bool? = nil,
        applyAlignment: Bool = false,
        applyProtection: Bool? = nil
    ) {
        self.numberFormat = numberFormat
        self.font = font
        self.fill = fill
        self.border = border
        self.styleFormat = styleFormat
        self.protection = protection
        self.applyNumberFormat = applyNumberFormat ?? (self.numberFormat != nil)
        self.applyFont = applyFont ?? (font != nil)
        self.applyFill = applyFill ?? (fill != nil)
        self.applyBorder = applyBorder ?? (border != nil)
        self.applyAlignment = applyAlignment
        self.applyProtection = applyProtection ?? (protection != nil)
    }

    public init(
        record: XLCellFormatRecord,
        numberFormats: OrderedSet<String>,
        fonts: OrderedSet<XLFont>,
        fills: OrderedSet<XLFill>,
        borders: OrderedSet<XLBorder>,
        cellStyleFormats: OrderedSet<XLCellStyleFormatRef>
    ) {
        self.numberFormat = Self.numberFormat(for: record.numberFormatID, in: numberFormats)
        self.font = Self.font(for: record.fontID, in: fonts)
        self.fill = Self.fill(for: record.fillID, in: fills)
        self.border = Self.border(for: record.borderID, in: borders)
        self.styleFormat = record.styleFormatID.flatMap { id in
            cellStyleFormats.indices.contains(id) ? cellStyleFormats[id] : nil
        }
        self.protection = record.protection
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
    public var protection: XLCellFormatProtection? = nil {
        didSet {
            applyProtection = protection != nil
        }
    }
    public var applyNumberFormat = false
    public var applyFont = false
    public var applyFill = false
    public var applyBorder = false
    public var applyAlignment = false
    public var applyProtection = false

    public func record(
        numberFormats: OrderedSet<String>,
        fonts: OrderedSet<XLFont>,
        fills: OrderedSet<XLFill>,
        borders: OrderedSet<XLBorder>,
        cellStyleFormats: OrderedSet<XLCellStyleFormatRef>
    ) throws -> XLCellFormatRecord {
        XLCellFormatRecord(
            numberFormatID: try numberFormatID(in: numberFormats),
            fontID: try fontID(in: fonts),
            fillID: try fillID(in: fills),
            borderID: try borderID(in: borders),
            styleFormatID: styleFormatID(in: cellStyleFormats),
            protection: protection,
            applyNumberFormat: applyNumberFormat,
            applyFont: applyFont,
            applyFill: applyFill,
            applyBorder: applyBorder,
            applyAlignment: applyAlignment,
            applyProtection: applyProtection
        )
    }

    public func record(styleStorage: XLStyleStorage) throws -> XLCellFormatRecord {
        try record(
            numberFormats: styleStorage.numberFormats,
            fonts: styleStorage.fonts,
            fills: styleStorage.fills,
            borders: styleStorage.borders,
            cellStyleFormats: styleStorage.cellStyleFormats
        )
    }

    public func collectStyle(stage: XLStyleCollectionStage, styleStorage: inout XLStyleStorage) throws {
        switch stage {
        case .numberFormats:
            if case let .format(format)? = numberFormat {
                styleStorage.numberFormats.append(format)
            }
        case .fonts:
            if let font {
                styleStorage.fonts.append(font)
            }
        case .fills:
            if let fill {
                styleStorage.fills.append(fill)
            }
        case .borders:
            if let border {
                styleStorage.borders.append(border)
            }
        case .cellStyleFormats:
            break
        case .cellFormats:
            let record = try self.record(styleStorage: styleStorage)
            styleStorage.cellFormats.append(record)
        }

        styleFormat?.collectStyle(stage: stage, styleStorage: &styleStorage)
    }

    private static func numberFormat(
        for numberFormatID: Int?,
        in numberFormats: OrderedSet<String>
    ) -> XLNumberFormat? {
        guard let numberFormatID else {
            return nil
        }

        if let format = XLNumberFormat.customNumberFormat(for: numberFormatID, in: numberFormats) {
            return .format(format)
        }

        return .builtin(id: numberFormatID)
    }

    private static func font(for fontID: Int?, in fonts: OrderedSet<XLFont>) -> XLFont? {
        guard let fontID,
              fonts.indices.contains(fontID)
        else {
            return nil
        }

        return fonts[fontID]
    }

    private static func fill(for fillID: Int?, in fills: OrderedSet<XLFill>) -> XLFill? {
        guard let fillID,
              fills.indices.contains(fillID)
        else {
            return nil
        }

        return fills[fillID]
    }

    private static func border(for borderID: Int?, in borders: OrderedSet<XLBorder>) -> XLBorder? {
        guard let borderID,
              borders.indices.contains(borderID)
        else {
            return nil
        }

        return borders[borderID]
    }

    private func fontID(in fonts: OrderedSet<XLFont>) throws -> Int? {
        guard let font else {
            return nil
        }

        guard let index = fonts.firstIndex(of: font) else {
            throw OPCError.missingFontRecord
        }

        return index
    }

    private func fillID(in fills: OrderedSet<XLFill>) throws -> Int? {
        guard let fill else {
            return nil
        }

        guard let index = fills.firstIndex(of: fill) else {
            throw OPCError.missingFillRecord
        }

        return index
    }

    private func borderID(in borders: OrderedSet<XLBorder>) throws -> Int? {
        guard let border else {
            return nil
        }

        guard let index = borders.firstIndex(of: border) else {
            throw OPCError.missingBorderRecord
        }

        return index
    }

    private func numberFormatID(in numberFormats: OrderedSet<String>) throws -> Int? {
        guard let numberFormat else {
            return nil
        }

        switch numberFormat {
        case let .builtin(id):
            return id
        case let .format(format):
            guard let id = XLNumberFormat.customNumberFormatID(for: format, in: numberFormats) else {
                throw OPCError.missingNumberFormatRecord
            }

            return id
        }
    }

    private func styleFormatID(in cellStyleFormats: OrderedSet<XLCellStyleFormatRef>) -> Int? {
        guard let styleFormat else {
            return nil
        }

        return cellStyleFormats.firstIndex(of: styleFormat)
    }
}
