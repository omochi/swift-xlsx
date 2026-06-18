import Foundation
import OrderedCollections

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

    public func xmlDocument(sharedStringStorage: OrderedSet<XLSharedStringRecord>) throws -> XMLDocument {
        let document = original?.clone() ?? XMLDocument()
        let sharedStringsElement = XMLUtils.ensureRootElement(name: "sst", in: document)
        sharedStringsElement.ensureNamespace(uri: .spreadsheet)
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
        sharedStringStorage: OrderedSet<XLSharedStringRecord>
    ) throws {
        sharedStringsElement.children = try XMLUtils.patchChildren(
            parentElement: sharedStringsElement,
            replacingElementName: "si",
            records: sharedStringStorage,
            makeElement: { record in
                try elementForWriting(record: record)
            }
        )
    }

    private func elementForWriting(
        record: XLSharedStringRecord
    ) throws -> XMLElement {
        switch record {
        case let .text(text):
            return Self.makeTextElement(for: text)
        case let .opaque(xmlString):
            return try XMLElement(xmlString: xmlString)
        }
    }

    public static func makeTextElement(for text: String) -> XMLElement {
        let itemElement = XMLElement(name: XMLName(name: "si"))
        let textElement = XMLElement(name: XMLName(name: "t"))
        if text != text.trimmingCharacters(in: .whitespacesAndNewlines) {
            textElement.attributes.append(XMLAttribute(
                name: XMLName(prefix: "xml", name: "space"),
                value: "preserve"
            ))
        }
        textElement.appendChild(XMLText(text))
        itemElement.appendChild(textElement)
        return itemElement
    }
}
