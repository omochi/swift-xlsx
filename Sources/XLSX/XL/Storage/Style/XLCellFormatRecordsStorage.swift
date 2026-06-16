public typealias XLCellFormatRecordsStorage = XLGenericRecordStorage<XLCellFormatRecord>

extension XLCellFormatRecordsStorage {
    @discardableResult
    public func register(_ format: XLCellFormat, fonts: XLFontRecordsStorage) throws -> Int {
        try register(format.record(fonts: fonts))
    }
}
