import OrderedCollections
import XLSXXML

public struct XLStyleStorage {
    public init(
        numberFormats: OrderedSet<String> = OrderedSet<String>(),
        fonts: OrderedSet<XLFont> = OrderedSet<XLFont>(),
        fills: OrderedSet<XLFill> = OrderedSet<XLFill>(),
        borders: OrderedSet<XLBorder> = OrderedSet<XLBorder>(),
        cellStyleFormats: OrderedSet<XLCellStyleFormatRef> = OrderedSet<XLCellStyleFormatRef>(),
        cellFormats: OrderedSet<XLCellFormatRecord> = OrderedSet<XLCellFormatRecord>()
    ) {
        self.numberFormats = numberFormats
        self.fonts = fonts
        self.fills = fills
        self.borders = borders
        self.cellStyleFormats = cellStyleFormats
        self.cellFormats = cellFormats
        ensureInitialRecords()
    }

    public init(xmlDocument: XMLDocument) throws {
        guard let stylesElement = xmlDocument.element(name: "styleSheet") else {
            throw OPCError.invalidStylesFile
        }

        let numberFormats = OrderedSet<String>(Self.readNumberFormats(in: stylesElement))
        let fonts = OrderedSet<XLFont>(Self.readFonts(in: stylesElement))
        let fills = OrderedSet<XLFill>(Self.readFills(in: stylesElement))
        let borders = OrderedSet<XLBorder>(Self.readBorders(in: stylesElement))
        let cellStyleFormats = OrderedSet<XLCellStyleFormatRef>(Self.readCellStyleFormats(
            in: stylesElement,
            numberFormats: numberFormats,
            fonts: fonts,
            fills: fills,
            borders: borders
        ))
        let cellFormats = OrderedSet<XLCellFormatRecord>(Self.readCellFormats(in: stylesElement))

        self.init(
            numberFormats: numberFormats,
            fonts: fonts,
            fills: fills,
            borders: borders,
            cellStyleFormats: cellStyleFormats,
            cellFormats: cellFormats
        )
    }

    public var numberFormats: OrderedSet<String>
    public var fonts: OrderedSet<XLFont>
    public var fills: OrderedSet<XLFill>
    public var borders: OrderedSet<XLBorder>
    public var cellStyleFormats: OrderedSet<XLCellStyleFormatRef>
    public var cellFormats: OrderedSet<XLCellFormatRecord>

    public var isEmpty: Bool {
        numberFormats.isEmpty &&
            fonts.isEmpty &&
            fills.isEmpty &&
            borders.isEmpty &&
            cellStyleFormats.isEmpty &&
            cellFormats.isEmpty
    }

    private mutating func ensureInitialRecords() {
        if fonts.isEmpty {
            fonts.append(XLFont())
        }

        if fills.isEmpty {
            fills.append(.pattern(.none))
            fills.append(.pattern(.gray125))
        }

        if borders.isEmpty {
            borders.append(XLBorder())
        }

        if cellStyleFormats.isEmpty {
            cellStyleFormats.append(XLCellStyleFormatRef(
                numberFormat: .builtin(id: 0),
                font: fonts.indices.contains(0) ? fonts[0] : nil,
                fill: fills.indices.contains(0) ? fills[0] : nil,
                border: borders.indices.contains(0) ? borders[0] : nil
            ))
        }

        if cellFormats.isEmpty {
            cellFormats.append(XLCellFormatRecord(
                numberFormatID: 0,
                fontID: 0,
                fillID: 0,
                borderID: 0,
                styleFormatID: 0
            ))
        }
    }

    private static func readNumberFormats(in stylesElement: XMLElement) -> [String] {
        guard let numberFormatsElement = stylesElement.elements(name: "numFmts").first else {
            return []
        }

        return numberFormatsElement.elements(name: "numFmt")
            .compactMap { element -> (id: Int, format: String)? in
                guard let id = XMLUtils.intAttribute(name: "numFmtId", in: element),
                      let format = element.attribute(name: "formatCode")
                else {
                    return nil
                }

                return (id, format)
            }
            .filter { $0.id >= XLNumberFormat.customFormatFirstID }
            .sorted { $0.id < $1.id }
            .map { $0.format }
    }

    private static func readFonts(in stylesElement: XMLElement) -> [XLFont] {
        guard let fontsElement = stylesElement.elements(name: "fonts").first else {
            return []
        }
        return fontsElement.elements(name: "font").map(XLFont.init(element:))
    }

    private static func readFills(in stylesElement: XMLElement) -> [XLFill] {
        guard let fillsElement = stylesElement.elements(name: "fills").first else {
            return []
        }
        return fillsElement.elements(name: "fill").map(XLFill.init(element:))
    }

    private static func readBorders(in stylesElement: XMLElement) -> [XLBorder] {
        guard let bordersElement = stylesElement.elements(name: "borders").first else {
            return []
        }
        return bordersElement.elements(name: "border").map(XLBorder.init(element:))
    }

    private static func readCellFormats(in stylesElement: XMLElement) -> [XLCellFormatRecord] {
        guard let cellXfsElement = stylesElement.elements(name: "cellXfs").first else {
            return []
        }
        return cellXfsElement.elements(name: "xf").map(XLCellFormatRecord.init(element:))
    }

    private static func readCellStyleFormats(
        in stylesElement: XMLElement,
        numberFormats: OrderedSet<String>,
        fonts: OrderedSet<XLFont>,
        fills: OrderedSet<XLFill>,
        borders: OrderedSet<XLBorder>
    ) -> [XLCellStyleFormatRef] {
        guard let cellStyleXfsElement = stylesElement.elements(name: "cellStyleXfs").first else {
            return []
        }

        return cellStyleXfsElement.elements(name: "xf").map { element in
            let cellFormat = XLCellFormat(
                record: XLCellFormatRecord(element: element),
                numberFormats: numberFormats,
                fonts: fonts,
                fills: fills,
                borders: borders,
                cellStyleFormats: OrderedSet<XLCellStyleFormatRef>()
            )
            return XLCellStyleFormatRef(
                numberFormat: cellFormat.numberFormat,
                font: cellFormat.font,
                fill: cellFormat.fill,
                border: cellFormat.border
            )
        }
    }
}
