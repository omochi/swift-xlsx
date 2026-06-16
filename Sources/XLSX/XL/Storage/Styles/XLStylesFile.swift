import Foundation

public final class XLStylesFile: OPCXMLFile {
    public init(cellFormats: [XLCellFormatRecord] = []) {
        self.cellFormats = cellFormats
        self.original = nil
    }

    public init(xmlDocument: XMLDocument) throws {
        guard let stylesElement = xmlDocument.element(name: "styleSheet") else {
            throw OPCError.invalidStylesFile
        }

        self.cellFormats = Self.cellFormats(in: stylesElement)
        self.original = xmlDocument
    }

    public var cellFormats: [XLCellFormatRecord]
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
        cellFormats.isEmpty
    }

    public func xmlDocument() throws -> XMLDocument {
        let document = original?.clone() ?? XMLDocument()
        let stylesElement = stylesElementForWriting(in: document)
        stylesElement.ensureNamespace(uri: .spreadsheet)
        writeCellFormats(to: stylesElement)
        return document
    }

    private static func cellFormats(in stylesElement: XMLElement) -> [XLCellFormatRecord] {
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

    private func writeCellFormats(to stylesElement: XMLElement) {
        if cellFormats.isEmpty && stylesElement.elements(name: "cellXfs").isEmpty {
            return
        }

        let cellXfsElement = cellXfsElementForWriting(in: stylesElement)
        cellXfsElement.setAttribute(name: "count", value: String(cellFormats.count))

        cellXfsElement.children = XMLUtils.patchChildren(
            in: cellXfsElement,
            replacingElementsNamed: "xf",
            with: cellFormats,
            makeElement: { cellFormat in
                cellFormat.xmlElement()
            }
        )
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
