public final class XLCellFormatObjectPool {
    public init(records: [XLCellFormatRecord] = []) {
        self.objects = []
        self.indexByRecord = [:]

        for record in records {
            _ = intern(record)
        }
    }

    public var objects: [XLCellFormatObject]
    private var indexByRecord: [XLCellFormatRecord: Int]

    public func intern(_ format: XLCellFormat) -> XLCellFormatObject {
        intern(format.record)
    }

    public func intern(_ record: XLCellFormatRecord) -> XLCellFormatObject {
        if let index = indexByRecord[record] {
            return objects[index]
        }

        let object = XLCellFormatObject(record: record)
        let index = objects.count
        objects.append(object)
        indexByRecord[record] = index
        return object
    }

    public func object(at index: Int) -> XLCellFormatObject? {
        guard objects.indices.contains(index) else {
            return nil
        }
        return objects[index]
    }

    func index(for object: XLCellFormatObject) -> Int? {
        indexByRecord[object.record]
    }

    func clone() -> XLCellFormatObjectPool {
        XLCellFormatObjectPool(records: objects.map(\.record))
    }
}
