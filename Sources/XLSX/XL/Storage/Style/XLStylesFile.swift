import Foundation
import OrderedCollections

public final class XLStylesFile {
    public init(
        styleStorage: XLStyleStorage,
        cellStyles: [XLCellStyle] = []
    ) {
        self.cellStyles = cellStyles
        self.original = nil
        ensureInitialCellStyles(styleStorage: styleStorage)
    }

    public convenience init(xmlDocument: XMLDocument) throws {
        let styleStorage = try XLStyleStorage(xmlDocument: xmlDocument)
        try self.init(
            xmlDocument: xmlDocument,
            styleStorage: styleStorage
        )
    }

    public convenience init(
        xmlDocument: XMLDocument,
        styleStorage: XLStyleStorage
    ) throws {
        guard let stylesElement = xmlDocument.element(name: "styleSheet") else {
            throw OPCError.invalidStylesFile
        }

        let cellStyles = Self.readCellStyles(
            in: stylesElement,
            styleStorage: styleStorage
        )
        self.init(
            styleStorage: styleStorage,
            cellStyles: cellStyles
        )
        self.original = xmlDocument
    }

    public var cellStyles: [XLCellStyle]
    public var original: XMLDocument?

    var defaultCellStyleFormat: XLCellStyleFormatRef? {
        cellStyles.first { $0.builtinID == 0 }?.format
    }

    public static func path(
        workbookPath: OPCFilePath,
        workbookRels: OPCRelsFile
    ) throws -> OPCFilePath {
        if let relationship = workbookRels.relationships.first(where: { $0.type == XMLNamespaceURI.styles.string }) {
            return try OPCFilePath(string: relationship.target).resolved(relativeTo: workbookPath)
        }
        return try OPCFilePath(string: "styles.xml").resolved(relativeTo: workbookPath)
    }

    public func xmlDocument(styleStorage: XLStyleStorage) throws -> XMLDocument {
        let styleStorage = styleStorageForWriting(styleStorage)
        let document = original?.clone() ?? XMLDocument()
        let stylesElement = XMLUtils.ensureRootElement(name: "styleSheet", in: document)
        stylesElement.ensureNamespace(uri: .spreadsheet)
        writeNumberFormats(to: stylesElement, styleStorage: styleStorage)
        try writeFonts(to: stylesElement, styleStorage: styleStorage)
        try writeFills(to: stylesElement, styleStorage: styleStorage)
        writeBorders(to: stylesElement, styleStorage: styleStorage)
        writeCellStyleFormats(to: stylesElement, styleStorage: styleStorage)
        writeCellFormats(to: stylesElement, styleStorage: styleStorage)
        writeCellStyles(to: stylesElement, styleStorage: styleStorage)
        return document
    }

    public func clone() -> XLStylesFile {
        let file = XLStylesFile.unchecked(
            cellStyles: cellStyles
        )
        file.original = original
        return file
    }

    public func collectStyle(styleStorage: inout XLStyleStorage) {
        for stage in XLStyleCollectionStage.allCases {
            collectStyle(stage: stage, styleStorage: &styleStorage)
        }
    }

    public func collectStyle(stage: XLStyleCollectionStage, styleStorage: inout XLStyleStorage) {
        for index in cellStyles.indices {
            guard let format = cellStyles[index].format else {
                continue
            }

            switch stage {
            case .numberFormats, .fonts, .fills, .borders, .cellFormats:
                format.collectStyle(stage: stage, styleStorage: &styleStorage)
            case .cellStyleFormats:
                styleStorage.cellStyleFormats.append(format)
            }
        }
    }

    private static func unchecked(cellStyles: [XLCellStyle]) -> XLStylesFile {
        let file = XLStylesFile(__unchecked: ())
        file.cellStyles = cellStyles
        file.original = nil
        return file
    }

    private init(__unchecked: Void = ()) {
        self.cellStyles = []
        self.original = nil
    }

    private func ensureInitialCellStyles(styleStorage: XLStyleStorage) {
        guard styleStorage.cellStyleFormats.indices.contains(0) else {
            return
        }
        let defaultCellStyleFormat = styleStorage.cellStyleFormats[0]

        if cellStyles.isEmpty {
            cellStyles.append(XLCellStyle(
                name: "Normal",
                format: defaultCellStyleFormat,
                builtinID: 0
            ))
        }
    }

    private func styleStorageForWriting(_ styleStorage: XLStyleStorage) -> XLStyleStorage {
        guard let defaultCellStyleFormat else {
            return styleStorage
        }

        var styleStorage = styleStorage
        if styleStorage.cellStyleFormats.firstIndex(of: defaultCellStyleFormat) != nil {
            return styleStorage
        }

        if styleStorage.cellStyleFormats.count == 1,
           isInitialDefaultCellStyleFormat(styleStorage.cellStyleFormats[0])
        {
            styleStorage.cellStyleFormats.remove(at: 0)
            styleStorage.cellStyleFormats.insert(defaultCellStyleFormat, at: 0)
        }

        return styleStorage
    }

    private func isInitialDefaultCellStyleFormat(_ format: XLCellStyleFormatRef) -> Bool {
        format.numberFormat == .builtin(id: 0) &&
            format.font == XLFont(record: XLFontRecord()) &&
            format.fill == .pattern(.none) &&
            format.border == XLBorder()
    }

    private static func readCellStyles(
        in stylesElement: XMLElement,
        styleStorage: XLStyleStorage
    ) -> [XLCellStyle] {
        guard let cellStylesElement = stylesElement.elements(name: "cellStyles").first else {
            return []
        }

        return cellStylesElement.elements(name: "cellStyle").map { element in
            XLCellStyle(element: element, cellStyleFormats: styleStorage.cellStyleFormats)
        }
    }

    private func writeNumberFormats(to stylesElement: XMLElement, styleStorage: XLStyleStorage) {
        let numberFormats = styleStorage.numberFormats
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

    private func writeFonts(to stylesElement: XMLElement, styleStorage: XLStyleStorage) throws {
        let fonts = styleStorage.fonts
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

    private func writeFills(to stylesElement: XMLElement, styleStorage: XLStyleStorage) throws {
        let fills = styleStorage.fills
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

    private func writeBorders(to stylesElement: XMLElement, styleStorage: XLStyleStorage) {
        let borders = styleStorage.borders
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

    private func writeCellFormats(to stylesElement: XMLElement, styleStorage: XLStyleStorage) {
        let cellFormats = styleStorage.cellFormats
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

    private func writeCellStyleFormats(to stylesElement: XMLElement, styleStorage: XLStyleStorage) {
        let cellStyleFormats = styleStorage.cellStyleFormats
        if cellStyleFormats.isEmpty && stylesElement.elements(name: "cellStyleXfs").isEmpty {
            return
        }

        let cellStyleXfsElement = ensureStyleSheetChildElement(name: "cellStyleXfs", in: stylesElement)
        cellStyleXfsElement.setAttribute(name: "count", value: String(cellStyleFormats.count))

        cellStyleXfsElement.children = XMLUtils.patchChildren(
            parentElement: cellStyleXfsElement,
            replacingElementName: "xf",
            records: cellStyleFormats,
            makeElement: { cellStyleFormat in
                cellStyleFormat.record(
                    numberFormats: styleStorage.numberFormats,
                    fonts: styleStorage.fonts,
                    fills: styleStorage.fills,
                    borders: styleStorage.borders
                ).xmlElement()
            }
        )
    }

    private func writeCellStyles(to stylesElement: XMLElement, styleStorage: XLStyleStorage) {
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
                    cellStyleFormats: styleStorage.cellStyleFormats,
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
