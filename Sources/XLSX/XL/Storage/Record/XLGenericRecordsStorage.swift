public final class XLGenericRecordsStorage<Record: Hashable>: RandomAccessCollection {
    public typealias Index = Int

    public init(records: [Record] = []) {
        self.storage = []
        self.indexByRecord = [:]

        for record in records {
            register(record)
        }
    }

    private var storage: [Record]
    private var indexByRecord: [Record: Int]

    public var startIndex: Int {
        storage.startIndex
    }

    public var endIndex: Int {
        storage.endIndex
    }

    public subscript(position: Int) -> Record {
        storage[position]
    }

    @discardableResult
    public func register(_ record: Record) -> Int {
        if let index = indexByRecord[record] {
            return index
        }

        let index = storage.count
        storage.append(record)
        indexByRecord[record] = index
        return index
    }

    public func record(at index: Int) -> Record? {
        guard indices.contains(index) else {
            return nil
        }
        return self[index]
    }

    public func index(for record: Record) -> Int? {
        indexByRecord[record]
    }

    public func clone() -> XLGenericRecordsStorage<Record> {
        XLGenericRecordsStorage(records: Array(self))
    }
}
