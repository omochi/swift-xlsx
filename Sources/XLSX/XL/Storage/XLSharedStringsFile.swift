import Foundation

public final class XLSharedStringsFile: OPCXMLFile {
    public init(
        items: [XLSharedStringItem] = [],
        count: Int? = nil,
        uniqueCount: Int? = nil
    ) {
        self.items = items
        self.count = count
        self.uniqueCount = uniqueCount
        self.original = nil
    }

    public init(xmlDocument: XMLDocument) throws {
        guard let sharedStringsElement = xmlDocument.element(name: "sst") else {
            throw OPCError.invalidSharedStringsFile
        }

        self.items = sharedStringsElement.elements(name: "si").map(Self.item(in:))
        self.count = sharedStringsElement.attribute(name: "count").flatMap(Int.init)
        self.uniqueCount = sharedStringsElement.attribute(name: "uniqueCount").flatMap(Int.init)
        self.original = xmlDocument
    }

    public var items: [XLSharedStringItem]
    public var count: Int?
    public var uniqueCount: Int?
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

    public func xmlDocument() -> XMLDocument {
        let document = original?.clone() ?? XMLDocument()
        let sharedStringsElement = sharedStringsElementForWriting(in: document)
        sharedStringsElement.ensureNamespace(uri: .spreadsheet)
        try! sharedStringsElement.setAttribute(
            name: "count",
            value: String(count ?? items.count)
        )
        try! sharedStringsElement.setAttribute(
            name: "uniqueCount",
            value: String(uniqueCount ?? items.count)
        )

        let sharedStringChildren = sharedStringElementsAndOtherChildren(in: sharedStringsElement)
        var itemElements: [XMLNode] = []
        for (index, item) in items.enumerated() {
            if index < sharedStringChildren.itemElements.count {
                let element = sharedStringChildren.itemElements[index]
                if Self.item(in: element) == item {
                    itemElements.append(element)
                    continue
                }
            }

            itemElements.append(Self.itemElement(for: item))
        }

        sharedStringsElement.children = itemElements + sharedStringChildren.otherChildren
        return document
    }

    private static func item(in element: XMLElement) -> XLSharedStringItem {
        if let text = element.elements(name: "t").first {
            return XLSharedStringItem(text: textValue(in: text))
        }

        let text = element.elements(name: "r")
            .compactMap { $0.elements(name: "t").first }
            .map(textValue(in:))
            .joined()
        return XLSharedStringItem(text: text)
    }

    private static func textValue(in element: XMLElement) -> String {
        element.children.compactMap { ($0 as? XMLText)?.value }.joined()
    }

    private func sharedStringsElementForWriting(in document: XMLDocument) -> XMLElement {
        if let element = document.element(name: "sst") {
            return element
        }

        let element = XMLElement(name: XMLName(name: "sst"))
        document.appendChild(element)
        return element
    }

    private func sharedStringElementsAndOtherChildren(
        in sharedStringsElement: XMLElement
    ) -> (itemElements: [XMLElement], otherChildren: [XMLNode]) {
        var itemElements: [XMLElement] = []
        var otherChildren: [XMLNode] = []
        for child in sharedStringsElement.children {
            guard let element = child as? XMLElement,
                  element.name.name == "si"
            else {
                otherChildren.append(child)
                continue
            }

            itemElements.append(element)
        }

        return (itemElements, otherChildren)
    }

    private static func itemElement(for item: XLSharedStringItem) -> XMLElement {
        let itemElement = XMLElement(name: XMLName(name: "si"))
        let textElement = XMLElement(name: XMLName(name: "t"))
        if item.text != item.text.trimmingCharacters(in: .whitespacesAndNewlines) {
            textElement.attributes.append(XMLAttribute(
                name: XMLName(prefix: "xml", name: "space"),
                value: "preserve"
            ))
        }
        textElement.appendChild(XMLText(item.text))
        itemElement.appendChild(textElement)
        return itemElement
    }
}
