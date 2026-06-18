public struct XLCellStyleFormatRef: Hashable {
    private struct Storage {
        var numberFormat: XLNumberFormat?
        var font: XLFont?
        var fill: XLFill?
        var border: XLBorder?
    }

    public init(
        numberFormat: XLNumberFormat? = nil,
        font: XLFont? = nil,
        fill: XLFill? = nil,
        border: XLBorder? = nil
    ) {
        self.box = Box(Storage(
            numberFormat: numberFormat,
            font: font,
            fill: fill,
            border: border
        ))
    }

    private let box: Box<Storage>

    public var identifier: ObjectIdentifier {
        ObjectIdentifier(box)
    }

    public static func == (lhs: XLCellStyleFormatRef, rhs: XLCellStyleFormatRef) -> Bool {
        lhs.identifier == rhs.identifier
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(identifier)
    }

    public var numberFormat: XLNumberFormat? {
        get {
            box.value.numberFormat
        }
        set {
            box.value.numberFormat = newValue
        }
    }

    public var font: XLFont? {
        get {
            box.value.font
        }
        set {
            box.value.font = newValue
        }
    }

    public var fill: XLFill? {
        get {
            box.value.fill
        }
        set {
            box.value.fill = newValue
        }
    }

    public var border: XLBorder? {
        get {
            box.value.border
        }
        set {
            box.value.border = newValue
        }
    }

    public func record(
        numberFormats: XLNumberFormatsStorage,
        fonts: XLFontRecordsStorage,
        fills: XLFillsStorage,
        borders: XLBordersStorage
    ) throws -> XLCellFormatRecord {
        try XLCellFormat(
            numberFormat: numberFormat,
            font: font,
            fill: fill,
            border: border,
            styleFormat: nil,
            applyNumberFormat: false,
            applyFont: false,
            applyFill: false,
            applyBorder: false
        ).record(
            numberFormats: numberFormats,
            fonts: fonts,
            fills: fills,
            borders: borders,
            cellStyleFormats: XLCellStyleFormatRefsStorage()
        )
    }

    public func collectStyle(stage: XLStyleCollectionStage, styleStorage: inout XLStyleStorage) {
        switch stage {
        case .numberFormats:
            if case let .format(format)? = numberFormat {
                styleStorage.numberFormats.register(format)
            }
        case .fonts:
            if let font {
                styleStorage.fonts.register(font.record)
            }
        case .fills:
            if let fill {
                styleStorage.fills.register(fill)
            }
        case .borders:
            if let border {
                styleStorage.borders.register(border)
            }
        case .cellStyleFormats:
            styleStorage.cellStyleFormats.register(self)
        case .cellFormats:
            break
        }
    }
}
