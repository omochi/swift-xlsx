public typealias XLCellFormatRecordsStorage = XLGenericRecordStorage<XLCellFormatRecord>

extension XLCellFormatRecordsStorage {
    @discardableResult
    public func register(_ format: XLCellFormat) -> Int {
        register(format.record)
    }
}
