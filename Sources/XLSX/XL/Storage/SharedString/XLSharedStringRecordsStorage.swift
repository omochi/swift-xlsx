public typealias XLSharedStringRecordsStorage = XLGenericRecordsStorage<XLSharedStringRecord>

extension XLSharedStringRecordsStorage {
    public init(xmlDocument: XMLDocument) throws {
        guard let sharedStringsElement = xmlDocument.element(name: "sst") else {
            throw OPCError.invalidSharedStringsFile
        }

        self.init(records: Self.sharedStringRecords(in: sharedStringsElement))
    }

    @discardableResult
    public mutating func register(_ text: String) -> Int {
        register(.text(text))
    }

    public func text(at index: Int) -> String? {
        guard case let .text(text) = record(at: index) else {
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
