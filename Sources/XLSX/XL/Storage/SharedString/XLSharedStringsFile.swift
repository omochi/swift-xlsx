import Foundation

public final class XLSharedStringsFile: XMLDocumentConvertible {
    public init(records: [XLSharedStringRecord] = []) {
        self.records = XLSharedStringRecordsStorage(records: records)
        self.original = nil
    }

    public init(xmlDocument: XMLDocument) throws {
        guard let sharedStringsElement = xmlDocument.element(name: "sst") else {
            throw OPCError.invalidSharedStringsFile
        }

        self.records = XLSharedStringRecordsStorage(records: Self.sharedStringRecords(in: sharedStringsElement))
        self.original = xmlDocument
    }

    public var original: XMLDocument?
    public var records: XLSharedStringRecordsStorage

    public static func path(
        workbookPath: OPCFilePath,
        workbookRels: OPCRelsFile
    ) throws -> OPCFilePath {
        if let relationship = workbookRels.relationships.first(where: { $0.type == XMLNamespaceURI.sharedStrings.string }) {
            return try OPCFilePath(string: relationship.target).resolved(relativeTo: workbookPath)
        }
        return try OPCFilePath(string: "sharedStrings.xml").resolved(relativeTo: workbookPath)
    }

    public func xmlDocument() throws -> XMLDocument {
        let document = original?.clone() ?? XMLDocument()
        let sharedStringsElement = XMLUtils.ensureRootElement(name: "sst", in: document)
        sharedStringsElement.ensureNamespace(uri: .spreadsheet)
        sharedStringsElement.setAttribute(name: "count", value: String(records.records.count))
        sharedStringsElement.setAttribute(name: "uniqueCount", value: String(records.records.count))
        try write(to: sharedStringsElement)
        return document
    }

    public func text(at index: Int) -> String? {
        guard case let .text(text) = records.record(at: index) else {
            return nil
        }
        return text
    }

    public func record(at index: Int) -> XLSharedStringRecord? {
        records.record(at: index)
    }

    public func clone() -> XLSharedStringsFile {
        let file = XLSharedStringsFile(records: records.records)
        file.original = original
        return file
    }

    private static func text(in element: XMLElement) -> String? {
        let childElements = element.children.compactMap { $0 as? XMLElement }
        let hasNonWhitespaceText = element.children.contains { child in
            guard let text = child as? XMLText else {
                return false
            }
            return !text.value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }

        if !hasNonWhitespaceText,
           childElements.count == 1,
           let text = childElements.first,
           text.name.name == "t"
        {
            return text.children.compactMap { ($0 as? XMLText)?.value }.joined()
        }

        return nil
    }

    private static func sharedStringRecords(in sharedStringsElement: XMLElement) -> [XLSharedStringRecord] {
        var records: [XLSharedStringRecord] = []
        for child in sharedStringsElement.children {
            guard let element = child as? XMLElement,
                  element.name.name == "si"
            else {
                continue
            }

            if let text = text(in: element) {
                records.append(.text(text))
            } else {
                records.append(.opaque(xmlString: element.xmlString))
            }
        }
        return records
    }

    private func write(to sharedStringsElement: XMLElement) throws {
        sharedStringsElement.children = try XMLUtils.patchChildren(
            parentElement: sharedStringsElement,
            replacingElementName: "si",
            records: records.records,
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
