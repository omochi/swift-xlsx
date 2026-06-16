import Foundation

public final class XLSharedStringsFile: OPCXMLFile {
    public init(records: [XLSharedStringRecord] = []) {
        self.records = records
        self.original = nil
    }

    public init(xmlDocument: XMLDocument) throws {
        guard let sharedStringsElement = xmlDocument.element(name: "sst") else {
            throw OPCError.invalidSharedStringsFile
        }

        self.records = Self.records(in: sharedStringsElement)
        self.original = xmlDocument
    }

    public var records: [XLSharedStringRecord]
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

    public func xmlDocument() throws -> XMLDocument {
        let document = original?.clone() ?? XMLDocument()
        let sharedStringsElement = sharedStringsElementForWriting(in: document)
        sharedStringsElement.ensureNamespace(uri: .spreadsheet)
        sharedStringsElement.setAttribute(name: "count", value: String(records.count))
        sharedStringsElement.setAttribute(name: "uniqueCount", value: String(records.count))
        try write(records: records, to: sharedStringsElement)
        return document
    }

    func text(at index: Int) -> String? {
        guard records.indices.contains(index) else {
            return nil
        }

        guard case let .text(text) = records[index] else {
            return nil
        }
        return text
    }

    func resolve(_ value: XLCellValue) -> XLCellValue {
        guard case let .opaqueSharedString(index) = value,
              let text = text(at: index)
        else {
            return value
        }

        return .string(text)
    }

    func apply(_ plan: XLSharedStringWritePlan) {
        records = plan.records
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

    private static func records(in sharedStringsElement: XMLElement) -> [XLSharedStringRecord] {
        var records: [XLSharedStringRecord] = []
        for (childIndex, child) in sharedStringsElement.children.enumerated() {
            guard let element = child as? XMLElement,
                  element.name.name == "si"
            else {
                continue
            }

            if let text = text(in: element) {
                records.append(.text(text))
            } else {
                records.append(.opaque(originalChildIndex: childIndex))
            }
        }
        return records
    }

    private func sharedStringsElementForWriting(in document: XMLDocument) -> XMLElement {
        if let element = document.element(name: "sst") {
            return element
        }

        let element = XMLElement(name: XMLName(name: "sst"))
        document.appendChild(element)
        return element
    }

    private func write(records: [XLSharedStringRecord], to sharedStringsElement: XMLElement) throws {
        var children: [XMLNode] = []
        var recordIndex = 0
        for child in sharedStringsElement.children {
            guard let element = child as? XMLElement,
                  element.name.name == "si"
            else {
                children.append(child)
                continue
            }

            if records.indices.contains(recordIndex) {
                children.append(try elementForWriting(record: records[recordIndex], in: sharedStringsElement))
                recordIndex += 1
            }
        }

        children += try records.dropFirst(recordIndex).map { try elementForWriting(record: $0, in: sharedStringsElement) as XMLNode }
        sharedStringsElement.children = children
    }

    private func elementForWriting(
        record: XLSharedStringRecord,
        in sharedStringsElement: XMLElement
    ) throws -> XMLElement {
        switch record {
        case let .text(text):
            return Self.makeTextElement(for: text)
        case let .opaque(originalChildIndex):
            guard sharedStringsElement.children.indices.contains(originalChildIndex),
                  let element = sharedStringsElement.children[originalChildIndex] as? XMLElement,
                  element.name.name == "si"
            else {
                throw OPCError.invalidSharedStringsFile
            }

            return element.clone()
        }
    }

    static func makeTextElement(for text: String) -> XMLElement {
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
