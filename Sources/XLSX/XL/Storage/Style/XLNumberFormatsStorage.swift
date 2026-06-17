public typealias XLNumberFormatsStorage = XLGenericRecordStorage<String>

extension XLNumberFormatsStorage {
    public func id(for format: String) -> Int? {
        guard let index = index(for: format) else {
            return nil
        }

        return XLNumberFormat.customFormatFirstID + index
    }

    public func format(for id: Int) -> String? {
        let index = id - XLNumberFormat.customFormatFirstID
        guard index >= 0 else {
            return nil
        }

        return record(at: index)
    }
}
