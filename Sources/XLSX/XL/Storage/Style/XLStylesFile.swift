import Foundation

public final class XLStylesFile: XMLDocumentConvertible {
    public init(
        fonts: [XLFontRecord] = [],
        fills: [XLFill] = [],
        borders: [XLBorder] = [],
        cellFormats: [XLCellFormatRecord] = []
    ) {
        self.fonts = XLFontRecordsStorage(records: fonts)
        self.fills = XLFillsStorage(records: fills)
        self.borders = XLBordersStorage(records: borders)
        self.cellFormats = XLCellFormatRecordsStorage(records: cellFormats)
        self.original = nil
    }

    public init(
        fonts: XLFontRecordsStorage = XLFontRecordsStorage(),
        fills: XLFillsStorage = XLFillsStorage(),
        borders: XLBordersStorage = XLBordersStorage(),
        cellFormats: XLCellFormatRecordsStorage
    ) {
        self.fonts = fonts
        self.fills = fills
        self.borders = borders
        self.cellFormats = cellFormats
        self.original = nil
    }

    public init(xmlDocument: XMLDocument) throws {
        guard let stylesElement = xmlDocument.element(name: "styleSheet") else {
            throw OPCError.invalidStylesFile
        }

        self.fonts = XLFontRecordsStorage(records: Self.readFonts(in: stylesElement))
        self.fills = XLFillsStorage(records: Self.readFills(in: stylesElement))
        self.borders = XLBordersStorage(records: Self.readBorders(in: stylesElement))
        self.cellFormats = XLCellFormatRecordsStorage(records: Self.readCellFormats(in: stylesElement))
        self.original = xmlDocument
    }

    public var fonts: XLFontRecordsStorage
    public var fills: XLFillsStorage
    public var borders: XLBordersStorage
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
        fonts.records.isEmpty && fills.records.isEmpty && borders.records.isEmpty && cellFormats.records.isEmpty
    }

    public func xmlDocument() throws -> XMLDocument {
        let document = original?.clone() ?? XMLDocument()
        let stylesElement = stylesElementForWriting(in: document)
        stylesElement.ensureNamespace(uri: .spreadsheet)
        try writeFonts(to: stylesElement)
        try writeFills(to: stylesElement)
        writeBorders(to: stylesElement)
        writeCellFormats(to: stylesElement)
        return document
    }

    func clone() -> XLStylesFile {
        let file = XLStylesFile(
            fonts: fonts.clone(),
            fills: fills.clone(),
            borders: borders.clone(),
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
}
