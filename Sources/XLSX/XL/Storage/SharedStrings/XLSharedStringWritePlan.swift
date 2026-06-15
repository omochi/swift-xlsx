struct XLSharedStringWritePlan {
    init(
        sharedStrings: XLSharedStringsFile,
        worksheets: [OPCFileWithPath<XLWorksheetFile>]
    ) {
        var usedItems: Set<XLSharedStringItem> = []
        var orderedItems: [XLSharedStringItem] = []
        var usedOpaqueIndices: Set<Int> = []

        for worksheet in worksheets {
            worksheet.file.collectSharedStringValues(
                usedItems: &usedItems,
                orderedItems: &orderedItems,
                usedOpaqueIndices: &usedOpaqueIndices
            )
        }

        var records: [XLSharedStringRecord] = []
        var indexByItem: [XLSharedStringItem: Int] = [:]
        var indexByOpaqueIndex: [Int: Int] = [:]

        func append(_ record: XLSharedStringRecord) {
            let newIndex = records.count
            records.append(record)
            if let item = record.item {
                indexByItem[item] = newIndex
            } else {
                indexByOpaqueIndex[record.index] = newIndex
            }
        }

        for record in sharedStrings.records {
            if let item = record.item {
                if usedItems.contains(item) {
                    append(record)
                }
            } else if usedOpaqueIndices.contains(record.index) {
                append(record)
            }
        }

        for item in orderedItems where indexByItem[item] == nil {
            append(XLSharedStringRecord(
                index: records.count,
                childIndex: nil,
                item: item,
                element: XLSharedStringsFile.makeItemElement(for: item)
            ))
        }

        self.records = records
        self.indexByItem = indexByItem
        self.indexByOpaqueIndex = indexByOpaqueIndex
    }

    var records: [XLSharedStringRecord]
    private var indexByItem: [XLSharedStringItem: Int]
    private var indexByOpaqueIndex: [Int: Int]

    func index(for value: XLCellValue) -> Int {
        switch value {
        case let .string(text):
            return indexByItem[XLSharedStringItem(text: text)] ?? 0
        case let .opaqueSharedString(index):
            return indexByOpaqueIndex[index] ?? index
        }
    }
}
