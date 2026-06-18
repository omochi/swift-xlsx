public typealias XLCellStyleFormatRefsStorage = XLGenericRecordsStorage<XLCellStyleFormatRef>

extension XLCellStyleFormatRefsStorage {
    func index(matching record: XLCellStyleFormatRef) -> Int? {
        if let index = index(for: record) {
            return index
        }

        return firstIndex { $0.hasSameStyleValues(as: record) }
    }

    mutating func canonicalRecord(for record: XLCellStyleFormatRef) -> XLCellStyleFormatRef {
        if let index = index(matching: record) {
            return self[index]
        }

        register(record)
        return record
    }
}
