public typealias XLCellFormatRecordsStorage = XLGenericRecordStorage<XLCellFormatRecord>

extension XLCellFormatRecordsStorage {
    @discardableResult
    public func register(
        _ format: XLCellFormat,
        fonts: XLFontRecordsStorage,
        fills: XLFillsStorage,
        borders: XLBordersStorage
    ) throws -> Int {
        try register(format.record(fonts: fonts, fills: fills, borders: borders))
    }
}
