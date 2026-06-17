public struct XLCellStyleFormatRef: Hashable {
    private struct Storage {
        var numberFormatID: Int?
        var font: XLFont?
        var fill: XLFill?
        var border: XLBorder?
    }

    public init(
        numberFormatID: Int? = nil,
        font: XLFont? = nil,
        fill: XLFill? = nil,
        border: XLBorder? = nil
    ) {
        self.box = Box(Storage(
            numberFormatID: numberFormatID,
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

    public var numberFormatID: Int? {
        get {
            box.value.numberFormatID
        }
        set {
            box.value.numberFormatID = newValue
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
        fonts: XLFontRecordsStorage,
        fills: XLFillsStorage,
        borders: XLBordersStorage
    ) throws -> XLCellFormatRecord {
        try XLCellFormat(
            numberFormatID: numberFormatID,
            font: font,
            fill: fill,
            border: border,
            styleFormat: nil,
            applyFont: false,
            applyFill: false,
            applyBorder: false
        ).record(fonts: fonts, fills: fills, borders: borders, cellStyleFormats: XLCellStyleFormatRefsStorage())
    }

    public func collectStyle(stage: XLStyleCollectionStage, styles: XLStylesFile) {
        switch stage {
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
            styles.cellStyleFormats.register(self)
        case .cellFormats:
            break
        }
    }
}
