import OrderedCollections

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
        numberFormats: OrderedSet<String>,
        fonts: OrderedSet<XLFontRecord>,
        fills: OrderedSet<XLFill>,
        borders: OrderedSet<XLBorder>
    ) -> XLCellFormatRecord {
        XLCellFormatRecord(
            numberFormatID: numberFormatID(in: numberFormats),
            fontID: font.flatMap { fonts.firstIndex(of: $0.record) },
            fillID: fill.flatMap { fills.firstIndex(of: $0) },
            borderID: border.flatMap { borders.firstIndex(of: $0) }
        )
    }

    private func numberFormatID(in numberFormats: OrderedSet<String>) -> Int? {
        guard let numberFormat else {
            return nil
        }

        switch numberFormat {
        case let .builtin(id):
            return id
        case let .format(format):
            return numberFormats.customNumberFormatID(for: format)
        }
    }

    public func collectStyle(stage: XLStyleCollectionStage, styleStorage: inout XLStyleStorage) {
        switch stage {
        case .numberFormats:
            if case let .format(format)? = numberFormat {
                styleStorage.numberFormats.append(format)
            }
        case .fonts:
            if let font {
                styleStorage.fonts.append(font.record)
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
            styleStorage.cellStyleFormats.append(self)
        case .cellFormats:
            break
        }
    }
}
