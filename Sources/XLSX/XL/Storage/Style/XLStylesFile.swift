import Foundation

public final class XLStylesFile: XMLDocumentConvertible {
    public init(
        fonts: XLFontRecordsStorage = XLFontRecordsStorage(),
        fills: XLFillsStorage = XLFillsStorage(),
        borders: XLBordersStorage = XLBordersStorage(),
        cellStyleFormats: XLCellStyleFormatRefsStorage = XLCellStyleFormatRefsStorage(),
        cellFormats: XLCellFormatRecordsStorage = XLCellFormatRecordsStorage()
    ) {
        self.fonts = fonts
        self.fills = fills
        self.borders = borders
        self.cellStyleFormats = cellStyleFormats
        self.cellFormats = cellFormats
        self.original = nil
    }

    public init(xmlDocument: XMLDocument) throws {
        guard let stylesElement = xmlDocument.element(name: "styleSheet") else {
            throw OPCError.invalidStylesFile
        }

        let fonts = XLFontRecordsStorage(records: Self.readFonts(in: stylesElement))
        let fills = XLFillsStorage(records: Self.readFills(in: stylesElement))
        let borders = XLBordersStorage(records: Self.readBorders(in: stylesElement))
        self.fonts = fonts
        self.fills = fills
        self.borders = borders
        self.cellStyleFormats = XLCellStyleFormatRefsStorage(records: Self.readCellStyleFormats(
            in: stylesElement,
            fonts: fonts,
            fills: fills,
            borders: borders
        ))
        self.cellFormats = XLCellFormatRecordsStorage(records: Self.readCellFormats(in: stylesElement))
        self.original = xmlDocument
    }

    public var fonts: XLFontRecordsStorage
    public var fills: XLFillsStorage
    public var borders: XLBordersStorage
    public var cellStyleFormats: XLCellStyleFormatRefsStorage
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
        fonts.records.isEmpty &&
            fills.records.isEmpty &&
            borders.records.isEmpty &&
            cellStyleFormats.records.isEmpty &&
            cellFormats.records.isEmpty
    }

    func resetToDefault() {
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
        cellStyleFormats = XLCellStyleFormatRefsStorage(records: [
            XLCellStyleFormatRef(
                numberFormatID: 0,
                font: XLFont(),
                fill: .pattern(.none),
                border: XLBorder()
            )
        ])
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
        let stylesElement = stylesElementForWriting(in: document)
        stylesElement.ensureNamespace(uri: .spreadsheet)
        try writeFonts(to: stylesElement)
        try writeFills(to: stylesElement)
        writeBorders(to: stylesElement)
        try writeCellStyleFormats(to: stylesElement)
        writeCellFormats(to: stylesElement)
        return document
    }

    func clone() -> XLStylesFile {
        let file = XLStylesFile(
            fonts: fonts.clone(),
            fills: fills.clone(),
            borders: borders.clone(),
            cellStyleFormats: cellStyleFormats.clone(),
            cellFormats: cellFormats.clone()
        )
        file.original = original
        return file
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
                fonts: fonts,
                fills: fills,
                borders: borders,
                cellStyleFormats: XLCellStyleFormatRefsStorage()
            )
            return XLCellStyleFormatRef(
                numberFormatID: cellFormat.numberFormatID,
                font: cellFormat.font,
                fill: cellFormat.fill,
                border: cellFormat.border
            )
        }
    }

    private func stylesElementForWriting(in document: XMLDocument) -> XMLElement {
        if let element = document.element(name: "styleSheet") {
            return element
        }

        let element = XMLElement(name: XMLName(name: "styleSheet"))
        document.appendChild(element)
        return element
    }

    private func writeFonts(to stylesElement: XMLElement) throws {
        let fonts = self.fonts.records
        if fonts.isEmpty && stylesElement.elements(name: "fonts").isEmpty {
            return
        }

        let fontsElement = fontsElementForWriting(in: stylesElement)
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
        let fills = self.fills.records
        if fills.isEmpty && stylesElement.elements(name: "fills").isEmpty {
            return
        }

        let fillsElement = fillsElementForWriting(in: stylesElement)
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
        let borders = self.borders.records
        if borders.isEmpty && stylesElement.elements(name: "borders").isEmpty {
            return
        }

        let bordersElement = bordersElementForWriting(in: stylesElement)
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
        let cellFormats = self.cellFormats.records
        if cellFormats.isEmpty && stylesElement.elements(name: "cellXfs").isEmpty {
            return
        }

        let cellXfsElement = cellXfsElementForWriting(in: stylesElement)
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
        let cellStyleFormats = self.cellStyleFormats.records
        if cellStyleFormats.isEmpty && stylesElement.elements(name: "cellStyleXfs").isEmpty {
            return
        }

        let cellStyleXfsElement = cellStyleXfsElementForWriting(in: stylesElement)
        cellStyleXfsElement.setAttribute(name: "count", value: String(cellStyleFormats.count))

        cellStyleXfsElement.children = try XMLUtils.patchChildren(
            parentElement: cellStyleXfsElement,
            replacingElementName: "xf",
            records: cellStyleFormats,
            makeElement: { cellStyleFormat in
                try cellStyleFormat.record(fonts: fonts, fills: fills, borders: borders).xmlElement()
            }
        )
    }

    private func fontsElementForWriting(in stylesElement: XMLElement) -> XMLElement {
        if let element = stylesElement.elements(name: "fonts").first {
            return element
        }

        let element = XMLElement(name: XMLName(name: "fonts"))
        stylesElement.appendChild(element)
        return element
    }

    private func fillsElementForWriting(in stylesElement: XMLElement) -> XMLElement {
        if let element = stylesElement.elements(name: "fills").first {
            return element
        }

        let element = XMLElement(name: XMLName(name: "fills"))
        stylesElement.appendChild(element)
        return element
    }

    private func bordersElementForWriting(in stylesElement: XMLElement) -> XMLElement {
        if let element = stylesElement.elements(name: "borders").first {
            return element
        }

        let element = XMLElement(name: XMLName(name: "borders"))
        stylesElement.appendChild(element)
        return element
    }

    private func cellXfsElementForWriting(in stylesElement: XMLElement) -> XMLElement {
        if let element = stylesElement.elements(name: "cellXfs").first {
            return element
        }

        let element = XMLElement(name: XMLName(name: "cellXfs"))
        stylesElement.appendChild(element)
        return element
    }

    private func cellStyleXfsElementForWriting(in stylesElement: XMLElement) -> XMLElement {
        if let element = stylesElement.elements(name: "cellStyleXfs").first {
            return element
        }

        let element = XMLElement(name: XMLName(name: "cellStyleXfs"))
        stylesElement.appendChild(element)
        return element
    }
}
