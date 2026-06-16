public final class XLCellFormatObject: Sendable {
    public init(record: XLCellFormatRecord) {
        self.record = record
    }

    public let record: XLCellFormatRecord

    public var format: XLCellFormat {
        XLCellFormat(record: record)
    }
}
