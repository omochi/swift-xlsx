import OrderedCollections
import XLSXXML

public final class XLSharedStringsFile {
    public init() {
        self.original = nil
    }

    public init(xmlDocument: XMLDocument) throws {
        guard xmlDocument.element(name: "sst") != nil else {
            throw OPCError.invalidSharedStringsFile
        }

        self.original = xmlDocument
    }

    public var original: XMLDocument?

    public static func path(
        workbookPath: OPCFilePath,
        workbookRels: OPCRelsFile
    ) throws -> OPCFilePath {
        if let relationship = workbookRels.relationships.first(where: { $0.type == XMLNamespaceURI.sharedStrings.string }) {
            return try OPCFilePath(string: relationship.target).resolved(relativeTo: workbookPath)
        }
        return try OPCFilePath(string: "sharedStrings.xml").resolved(relativeTo: workbookPath)
    }

    public static func readStorage(xmlDocument: XMLDocument) throws -> OrderedSet<XLText> {
        guard let sharedStringsElement = xmlDocument.element(name: "sst") else {
            throw OPCError.invalidSharedStringsFile
        }

        return OrderedSet(texts(in: sharedStringsElement))
    }

    public func xmlDocument(sharedStringStorage: OrderedSet<XLText>) throws -> XMLDocument {
        let document = original?.clone() ?? XMLDocument()
        let sharedStringsElement = XMLUtils.ensureRootElement(name: "sst", in: document)
        sharedStringsElement.setDefaultNamespace(uri: .spreadsheet)
        sharedStringsElement.setAttribute(name: "count", value: String(sharedStringStorage.count))
        sharedStringsElement.setAttribute(name: "uniqueCount", value: String(sharedStringStorage.count))
        try write(to: sharedStringsElement, sharedStringStorage: sharedStringStorage)
        return document
    }

    public func clone() -> XLSharedStringsFile {
        let file = XLSharedStringsFile()
        file.original = original
        return file
    }

    private func write(
        to sharedStringsElement: XMLElement,
        sharedStringStorage: OrderedSet<XLText>
    ) throws {
        sharedStringsElement.children = try XMLUtils.patchChildren(
            parentElement: sharedStringsElement,
            replacingElementName: "si",
            records: sharedStringStorage,
            makeElement: { text in
                try text.xmlElement(name: "si")
            }
        )
    }

    private static func texts(in sharedStringsElement: XMLElement) -> [XLText] {
        var texts: [XLText] = []
        for child in sharedStringsElement.children {
            guard let element = child as? XMLElement,
                  element.name.name == "si"
            else {
                continue
            }

            texts.append(XLText(element: element))
        }
        return texts
    }
}
