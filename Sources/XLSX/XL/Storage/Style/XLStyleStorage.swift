public struct XLStyleStorage {
    public init(
        numberFormats: XLNumberFormatsStorage = XLNumberFormatsStorage(),
        fonts: XLFontRecordsStorage = XLFontRecordsStorage(),
        fills: XLFillsStorage = XLFillsStorage(),
        borders: XLBordersStorage = XLBordersStorage(),
        cellStyleFormats: XLCellStyleFormatRefsStorage = XLCellStyleFormatRefsStorage(),
        cellFormats: XLCellFormatRecordsStorage = XLCellFormatRecordsStorage()
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

        let numberFormats = XLNumberFormatsStorage(records: Self.readNumberFormats(in: stylesElement))
        let fonts = XLFontRecordsStorage(records: Self.readFonts(in: stylesElement))
        let fills = XLFillsStorage(records: Self.readFills(in: stylesElement))
        let borders = XLBordersStorage(records: Self.readBorders(in: stylesElement))
        let cellStyleFormats = XLCellStyleFormatRefsStorage(records: Self.readCellStyleFormats(
            in: stylesElement,
            numberFormats: numberFormats,
            fonts: fonts,
            fills: fills,
            borders: borders
        ))
        let cellFormats = XLCellFormatRecordsStorage(records: Self.readCellFormats(in: stylesElement))

        self.init(
            numberFormats: numberFormats,
            fonts: fonts,
            fills: fills,
            borders: borders,
            cellStyleFormats: cellStyleFormats,
            cellFormats: cellFormats
        )
    }

    public var numberFormats: XLNumberFormatsStorage
    public var fonts: XLFontRecordsStorage
    public var fills: XLFillsStorage
    public var borders: XLBordersStorage
    public var cellStyleFormats: XLCellStyleFormatRefsStorage
    public var cellFormats: XLCellFormatRecordsStorage

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
            fonts.register(XLFontRecord())
        }

        if fills.isEmpty {
            fills.register(.pattern(.none))
            fills.register(.pattern(.gray125))
        }

        if borders.isEmpty {
            borders.register(XLBorder())
        }

        if cellStyleFormats.isEmpty {
            cellStyleFormats.register(XLCellStyleFormatRef(
                numberFormat: .builtin(id: 0),
                font: fonts.record(at: 0).map(XLFont.init(record:)),
                fill: fills.record(at: 0),
                border: borders.record(at: 0)
            ))
        }

        if cellFormats.isEmpty {
            cellFormats.register(XLCellFormatRecord(
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

    private static func readFonts(in stylesElement: XMLElement) -> [XLFontRecord] {
        guard let fontsElement = stylesElement.elements(name: "fonts").first else {
            return []
        }
        return fontsElement.elements(name: "font").map(XLFontRecord.init(element:))
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
        numberFormats: XLNumberFormatsStorage,
        fonts: XLFontRecordsStorage,
        fills: XLFillsStorage,
        borders: XLBordersStorage
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
                cellStyleFormats: XLCellStyleFormatRefsStorage()
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
