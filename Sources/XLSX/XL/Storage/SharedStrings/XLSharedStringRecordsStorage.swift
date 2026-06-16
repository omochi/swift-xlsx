public typealias XLSharedStringRecordsStorage = XLGenericRecordStorage<XLSharedStringRecord>

extension XLSharedStringRecordsStorage {
    @discardableResult
    public func register(_ text: String) -> Int {
        register(.text(text))
    }
}
