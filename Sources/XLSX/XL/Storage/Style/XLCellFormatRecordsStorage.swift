public typealias XLCellFormatRecordsStorage = XLGenericRecordsStorage<XLCellFormatRecord>

extension XLCellFormatRecordsStorage {
    @discardableResult
    public func register(
        _ format: XLCellFormat,
        styles: XLStylesFile
    ) throws -> Int {
        try register(format.record(
            numberFormats: styles.numberFormats,
            fonts: styles.fonts,
            fills: styles.fills,
            borders: styles.borders,
            cellStyleFormats: styles.cellStyleFormats
        ))
    }
}
