import OrderedCollections

extension OrderedSet where Element == String {
    public func customNumberFormatID(for format: String) -> Int? {
        guard let index = firstIndex(of: format) else {
            return nil
        }

        return XLNumberFormat.customFormatFirstID + index
    }

    public func customNumberFormat(for id: Int) -> String? {
        let index = id - XLNumberFormat.customFormatFirstID
        guard indices.contains(index) else {
            return nil
        }

        return self[index]
    }
}
