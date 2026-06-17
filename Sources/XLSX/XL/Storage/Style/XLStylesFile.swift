import Foundation

public final class XLStylesFile: XMLDocumentConvertible {
    public init(
        numberFormats: XLNumberFormatsStorage = XLNumberFormatsStorage(),
        fonts: XLFontRecordsStorage = XLFontRecordsStorage(),
        fills: XLFillsStorage = XLFillsStorage(),
        borders: XLBordersStorage = XLBordersStorage(),
        cellStyleFormats: XLCellStyleFormatRefsStorage = XLCellStyleFormatRefsStorage(),
        cellStyles: [XLCellStyle] = [],
        cellFormats: XLCellFormatRecordsStorage = XLCellFormatRecordsStorage()
    ) {
        self.numberFormats = numberFormats
        self.fonts = fonts
        self.fills = fills
        self.borders = borders
        self.cellStyleFormats = cellStyleFormats
        self.cellStyles = cellStyles
        self.cellFormats = cellFormats
        self.original = nil
    }

    public init(xmlDocument: XMLDocument) throws {
        guard let stylesElement = xmlDocument.element(name: "styleSheet") else {
            throw OPCError.invalidStylesFile
        }

        let numberFormats = XLNumberFormatsStorage(records: Self.readNumberFormats(in: stylesElement))
        let fonts = XLFontRecordsStorage(records: Self.readFonts(in: stylesElement))
        let fills = XLFillsStorage(records: Self.readFills(in: stylesElement))
        let borders = XLBordersStorage(records: Self.readBorders(in: stylesElement))
        self.numberFormats = numberFormats
        self.fonts = fonts
        self.fills = fills
        self.borders = borders
        let cellStyleFormats = XLCellStyleFormatRefsStorage(records: Self.readCellStyleFormats(
            in: stylesElement,
            numberFormats: numberFormats,
            fonts: fonts,
            fills: fills,
            borders: borders
        ))
        self.cellStyleFormats = cellStyleFormats
        self.cellStyles = Self.readCellStyles(
            in: stylesElement,
            cellStyleFormats: cellStyleFormats
        )
        self.cellFormats = XLCellFormatRecordsStorage(records: Self.readCellFormats(in: stylesElement))
        self.original = xmlDocument
    }

    public var numberFormats: XLNumberFormatsStorage
    public var fonts: XLFontRecordsStorage
    public var fills: XLFillsStorage
    public var borders: XLBordersStorage
    public var cellStyleFormats: XLCellStyleFormatRefsStorage
    public var cellStyles: [XLCellStyle]
    public var cellFormats: XLCellFormatRecordsStorage
    public var original: XMLDocument?

    public static func path(
        workbookPath: OPCFilePath,
        workbookRels: OPCRelsFile
    ) throws -> OPCFilePath {
        if let relationship = workbookRels.relationships.first(where: { $0.type == XMLNamespaceURI.styles.string }) {
            return try OPCFilePath(string: relationship.target).resolved(relativeTo: workbookPath)
        }
        return try OPCFilePath(string: "styles.xml").resolved(relativeTo: workbookPath)
    }

    public var isEmpty: Bool {
        numberFormats.isEmpty &&
            fonts.isEmpty &&
            fills.isEmpty &&
            borders.isEmpty &&
            cellStyleFormats.isEmpty &&
            cellStyles.isEmpty &&
            cellFormats.isEmpty
    }

    public func resetCollectableStyleElements() {
        numberFormats = XLNumberFormatsStorage()
        fonts = XLFontRecordsStorage(records: [
            XLFontRecord()
        ])
        fills = XLFillsStorage(records: [
            .pattern(.none),
            .pattern(.gray125)
        ])
        borders = XLBordersStorage(records: [
            XLBorder()
        ])
        let defaultCellStyleFormat = XLCellStyleFormatRef(
            numberFormat: .builtin(id: 0),
            font: XLFont(),
            fill: .pattern(.none),
            border: XLBorder()
        )
        cellStyleFormats = XLCellStyleFormatRefsStorage(records: [
            defaultCellStyleFormat
        ])
        if let defaultCellStyleIndex = cellStyles.firstIndex(where: { $0.builtinID == 0 }) {
            cellStyles[defaultCellStyleIndex].format = defaultCellStyleFormat
        } else {
            cellStyles.insert(
                XLCellStyle(name: "Normal", format: defaultCellStyleFormat, builtinID: 0),
                at: 0
            )
        }
        for cellStyle in cellStyles {
            if let format = cellStyle.format {
                cellStyleFormats.register(format)
            }
        }
        cellFormats = XLCellFormatRecordsStorage(records: [
            XLCellFormatRecord(
                numberFormatID: 0,
                fontID: 0,
                fillID: 0,
                borderID: 0,
                styleFormatID: 0
            )
        ])
    }

    public func xmlDocument() throws -> XMLDocument {
        let document = original?.clone() ?? XMLDocument()
        let stylesElement = XMLUtils.ensureRootElement(name: "styleSheet", in: document)
        stylesElement.ensureNamespace(uri: .spreadsheet)
        writeNumberFormats(to: stylesElement)
        try writeFonts(to: stylesElement)
        try writeFills(to: stylesElement)
        writeBorders(to: stylesElement)
        try writeCellStyleFormats(to: stylesElement)
        writeCellFormats(to: stylesElement)
        writeCellStyles(to: stylesElement)
        return document
    }

    public func clone() -> XLStylesFile {
        let file = XLStylesFile(
            numberFormats: numberFormats.clone(),
            fonts: fonts.clone(),
            fills: fills.clone(),
            borders: borders.clone(),
            cellStyleFormats: cellStyleFormats.clone(),
            cellStyles: cellStyles,
            cellFormats: cellFormats.clone()
        )
        file.original = original
        return file
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

    private static func readCellStyles(
        in stylesElement: XMLElement,
        cellStyleFormats: XLCellStyleFormatRefsStorage
    ) -> [XLCellStyle] {
        guard let cellStylesElement = stylesElement.elements(name: "cellStyles").first else {
            return []
        }

        return cellStylesElement.elements(name: "cellStyle").map { element in
            XLCellStyle(element: element, cellStyleFormats: cellStyleFormats)
        }
    }

    private func writeNumberFormats(to stylesElement: XMLElement) {
        let numberFormats = self.numberFormats
        if numberFormats.isEmpty && stylesElement.elements(name: "numFmts").isEmpty {
            return
        }

        let numberFormatsElement = ensureStyleSheetChildElement(name: "numFmts", in: stylesElement)
        numberFormatsElement.setAttribute(name: "count", value: String(numberFormats.count))

        numberFormatsElement.children = XMLUtils.patchChildren(
            parentElement: numberFormatsElement,
            replacingElementName: "numFmt",
            records: Array(numberFormats.enumerated()),
            makeElement: { item in
                let (index, format) = item
                let element = XMLElement(name: XMLName(name: "numFmt"))
                element.setAttribute(
                    name: "numFmtId",
                    value: String(XLNumberFormat.customFormatFirstID + index)
                )
                element.setAttribute(name: "formatCode", value: format)
                return element
            }
        )
    }

    private func writeFonts(to stylesElement: XMLElement) throws {
        let fonts = self.fonts
        if fonts.isEmpty && stylesElement.elements(name: "fonts").isEmpty {
            return
        }

        let fontsElement = ensureStyleSheetChildElement(name: "fonts", in: stylesElement)
        fontsElement.setAttribute(name: "count", value: String(fonts.count))

        fontsElement.children = try XMLUtils.patchChildren(
            parentElement: fontsElement,
            replacingElementName: "font",
            records: fonts,
            makeElement: { font in
                try font.xmlElement()
            }
        )
    }

    private func writeFills(to stylesElement: XMLElement) throws {
        let fills = self.fills
        if fills.isEmpty && stylesElement.elements(name: "fills").isEmpty {
            return
        }

        let fillsElement = ensureStyleSheetChildElement(name: "fills", in: stylesElement)
        fillsElement.setAttribute(name: "count", value: String(fills.count))

        fillsElement.children = try XMLUtils.patchChildren(
            parentElement: fillsElement,
            replacingElementName: "fill",
            records: fills,
            makeElement: { fill in
                try fill.xmlElement()
            }
        )
    }

    private func writeBorders(to stylesElement: XMLElement) {
        let borders = self.borders
        if borders.isEmpty && stylesElement.elements(name: "borders").isEmpty {
            return
        }

        let bordersElement = ensureStyleSheetChildElement(name: "borders", in: stylesElement)
        bordersElement.setAttribute(name: "count", value: String(borders.count))

        bordersElement.children = XMLUtils.patchChildren(
            parentElement: bordersElement,
            replacingElementName: "border",
            records: borders,
            makeElement: { border in
                border.xmlElement()
            }
        )
    }

    private func writeCellFormats(to stylesElement: XMLElement) {
        let cellFormats = self.cellFormats
        if cellFormats.isEmpty && stylesElement.elements(name: "cellXfs").isEmpty {
            return
        }

        let cellXfsElement = ensureStyleSheetChildElement(name: "cellXfs", in: stylesElement)
        cellXfsElement.setAttribute(name: "count", value: String(cellFormats.count))

        cellXfsElement.children = XMLUtils.patchChildren(
            parentElement: cellXfsElement,
            replacingElementName: "xf",
            records: cellFormats,
            makeElement: { cellFormat in
                cellFormat.xmlElement()
            }
        )
    }

    private func writeCellStyleFormats(to stylesElement: XMLElement) throws {
        let cellStyleFormats = self.cellStyleFormats
        if cellStyleFormats.isEmpty && stylesElement.elements(name: "cellStyleXfs").isEmpty {
            return
        }

        let cellStyleXfsElement = ensureStyleSheetChildElement(name: "cellStyleXfs", in: stylesElement)
        cellStyleXfsElement.setAttribute(name: "count", value: String(cellStyleFormats.count))

        cellStyleXfsElement.children = try XMLUtils.patchChildren(
            parentElement: cellStyleXfsElement,
            replacingElementName: "xf",
            records: cellStyleFormats,
            makeElement: { cellStyleFormat in
                try cellStyleFormat.record(
                    numberFormats: numberFormats,
                    fonts: fonts,
                    fills: fills,
                    borders: borders
                ).xmlElement()
            }
        )
    }

    private func writeCellStyles(to stylesElement: XMLElement) {
        if cellStyles.isEmpty && stylesElement.elements(name: "cellStyles").isEmpty {
            return
        }

        let revisionNamespacePrefix = stylesElement.ensureNamespaceURI(prefix: "xr", uri: .spreadsheetRevision)
        let cellStylesElement = ensureStyleSheetChildElement(name: "cellStyles", in: stylesElement)
        cellStylesElement.setAttribute(name: "count", value: String(cellStyles.count))

        cellStylesElement.children = XMLUtils.patchChildren(
            parentElement: cellStylesElement,
            replacingElementName: "cellStyle",
            records: cellStyles,
            makeElement: { cellStyle in
                cellStyle.xmlElement(
                    cellStyleFormats: cellStyleFormats,
                    revisionNamespacePrefix: revisionNamespacePrefix
                )
            }
        )
    }

    private func ensureStyleSheetChildElement(name: String, in stylesElement: XMLElement) -> XMLElement {
        XMLUtils.ensureChildElement(
            name: name,
            in: stylesElement,
            insertionIndex: { self.styleSheetChildInsertionIndex(name: name, in: stylesElement) }
        )
    }

    private func styleSheetChildInsertionIndex(name: String, in stylesElement: XMLElement) -> Int? {
        guard let order = Self.styleSheetChildOrderByName[name] else {
            return nil
        }

        return stylesElement.children.firstIndex { child in
            guard let childElement = child as? XMLElement,
                  let childOrder = Self.styleSheetChildOrderByName[childElement.name.name]
            else {
                return false
            }
            return childOrder > order
        }
    }

    private static let styleSheetChildOrderNames: [String] = [
        "numFmts",
        "fonts",
        "fills",
        "borders",
        "cellStyleXfs",
        "cellXfs",
        "cellStyles",
        "dxfs",
        "tableStyles",
        "colors",
        "extLst",
    ]

    private static let styleSheetChildOrderByName: [String: Int] = Dictionary(
        uniqueKeysWithValues: styleSheetChildOrderNames.enumerated().map { nameIndex, name in
            (name, nameIndex)
        }
    )

}
