public final class XLGenericRecordStorage<Record: Hashable> {
    public init(records: [Record] = []) {
        self.records = []
        self.indexByRecord = [:]

        for record in records {
            register(record)
        }
    }

    public private(set) var records: [Record]
    private var indexByRecord: [Record: Int]

    public var isEmpty: Bool {
        records.isEmpty
    }

    @discardableResult
    public func register(_ record: Record) -> Int {
        if let index = indexByRecord[record] {
            return index
        }

        let index = records.count
        records.append(record)
        indexByRecord[record] = index
        return index
    }

    public func record(at index: Int) -> Record? {
        guard records.indices.contains(index) else {
            return nil
        }
        return records[index]
    }

    func index(for record: Record) -> Int? {
        indexByRecord[record]
    }

    func clone() -> XLGenericRecordStorage<Record> {
        XLGenericRecordStorage(records: records)
    }
}
