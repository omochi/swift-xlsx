public typealias XLCellFormatRecordsStorage = XLGenericRecordsStorage<XLCellFormatRecord>

extension XLCellFormatRecordsStorage {
    @discardableResult
    public func register(
        _ format: XLCellFormat,
        styleStorage: XLStyleStorage
    ) throws -> Int {
        try register(format.record(styleStorage: styleStorage))
    }
}
