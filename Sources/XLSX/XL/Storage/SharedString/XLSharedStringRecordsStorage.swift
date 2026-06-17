public typealias XLSharedStringRecordsStorage = XLGenericRecordsStorage<XLSharedStringRecord>

extension XLSharedStringRecordsStorage {
    @discardableResult
    public func register(_ text: String) -> Int {
        register(.text(text))
    }
}
