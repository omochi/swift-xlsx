import OrderedCollections

extension OrderedSet where Element == XLSharedStringRecord {
    public init(xmlDocument: XMLDocument) throws {
        guard let sharedStringsElement = xmlDocument.element(name: "sst") else {
            throw OPCError.invalidSharedStringsFile
        }

        self.init(Self.sharedStringRecords(in: sharedStringsElement))
    }

    public func text(at index: Int) -> String? {
        guard indices.contains(index),
              case let .text(text) = self[index]
        else {
            return nil
        }
        return text
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
}
