struct XLSharedStringWritePlan {
    init(
        sharedStrings: XLSharedStringsFile,
        workbook: XLWorkbookFile
    ) {
        var collector = XLSharedStringCollector()
        workbook.collectSharedStringValues(into: &collector)

        var records: [XLSharedStringRecord] = []
        var indexByText: [String: Int] = [:]
        var indexByOpaqueIndex: [Int: Int] = [:]

        func append(_ record: XLSharedStringRecord, originalIndex: Int? = nil) {
            let newIndex = records.count
            records.append(record)
            switch record {
            case let .text(text):
                indexByText[text] = newIndex
            case .opaque:
                guard let originalIndex else {
                    return
                }
                indexByOpaqueIndex[originalIndex] = newIndex
            }
        }

        for (originalIndex, record) in sharedStrings.records.enumerated() {
            switch record {
            case let .text(text):
                if collector.usedTexts.contains(text) {
                    append(record)
                }
            case .opaque:
                if collector.usedOpaqueIndices.contains(originalIndex) {
                    append(record, originalIndex: originalIndex)
                }
            }
        }

        for text in collector.orderedTexts where indexByText[text] == nil {
            append(.text(text))
        }

        self.records = records
        self.indexByText = indexByText
        self.indexByOpaqueIndex = indexByOpaqueIndex
    }

    var records: [XLSharedStringRecord]
    private var indexByText: [String: Int]
    private var indexByOpaqueIndex: [Int: Int]

    func stringIndex(for text: String) throws -> Int {
        guard let index = indexByText[text] else {
            throw OPCError.invalidSharedStringsFile
        }
        return index
    }

    func opaqueSharedStringIndex(for originalIndex: Int) throws -> Int {
        guard let index = indexByOpaqueIndex[originalIndex] else {
            throw OPCError.invalidSharedStringsFile
        }
        return index
    }
}
