import Foundation

public final class XLStylesFile: OPCXMLFile {
    public init() {
        self.original = nil
    }

    public init(xmlDocument: XMLDocument) throws {
        guard xmlDocument.element(name: "styleSheet") != nil else {
            throw OPCError.invalidStylesFile
        }

        self.original = xmlDocument
    }

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

    static func isEmptyStyles(_ document: XMLDocument) -> Bool {
        let elements = document.children.compactMap { $0 as? XMLElement }
        guard elements.count == 1,
              let stylesElement = elements.first,
              stylesElement.name.name == "styleSheet"
        else {
            return false
        }

        return stylesElement.children.compactMap { $0 as? XMLElement }.isEmpty
    }

    public func xmlDocument() throws -> XMLDocument {
        let document = original?.clone() ?? XMLDocument()
        let stylesElement = stylesElementForWriting(in: document)
        stylesElement.ensureNamespace(uri: .spreadsheet)
        return document
    }

    private func stylesElementForWriting(in document: XMLDocument) -> XMLElement {
        if let element = document.element(name: "styleSheet") {
            return element
        }

        let element = XMLElement(name: XMLName(name: "styleSheet"))
        document.appendChild(element)
        return element
    }
}
