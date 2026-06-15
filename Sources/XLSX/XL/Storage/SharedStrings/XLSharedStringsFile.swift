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

    public func xmlDocument() -> XMLDocument {
        let document = original?.clone() ?? XMLDocument()
        let sharedStringsElement = sharedStringsElementForWriting(in: document)
        sharedStringsElement.ensureNamespace(uri: .spreadsheet)
        sharedStringsElement.setAttribute(name: "count", value: String(records.count))
        sharedStringsElement.setAttribute(name: "uniqueCount", value: String(records.count))
        write(records: records, to: sharedStringsElement)
        return document
    }

    func item(at index: Int) -> XLSharedStringItem? {
        records.first { $0.index == index }?.item
    }

    func resolve(_ value: XLCellValue) -> XLCellValue {
        guard case let .opaqueSharedString(index) = value,
              let item = item(at: index)
        else {
            return value
        }

        return .string(item.text)
    }

    func apply(_ plan: XLSharedStringWritePlan) {
        records = plan.records
    }

    private static func item(in element: XMLElement) -> XLSharedStringItem? {
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
            return XLSharedStringItem(text: text.children.compactMap { ($0 as? XMLText)?.value }.joined())
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

            records.append(XLSharedStringRecord(
                index: records.count,
                childIndex: childIndex,
                item: item(in: element),
                element: element
            ))
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

    private func write(records: [XLSharedStringRecord], to sharedStringsElement: XMLElement) {
        var recordsByChildIndex: [Int: XLSharedStringRecord] = [:]
        var appendedRecords: [XLSharedStringRecord] = []
        for record in records {
            if let childIndex = record.childIndex {
                recordsByChildIndex[childIndex] = record
            } else {
                appendedRecords.append(record)
            }
        }

        var children: [XMLNode] = []
        for (childIndex, child) in sharedStringsElement.children.enumerated() {
            guard let element = child as? XMLElement,
                  element.name.name == "si"
            else {
                children.append(child)
                continue
            }

            if let record = recordsByChildIndex[childIndex] {
                children.append(record.element.clone())
            }
        }

        children += appendedRecords.map { $0.element.clone() as XMLNode }
        sharedStringsElement.children = children
    }

    static func makeItemElement(for item: XLSharedStringItem) -> XMLElement {
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
