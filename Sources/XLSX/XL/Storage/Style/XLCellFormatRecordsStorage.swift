public typealias XLCellFormatRecordsStorage = XLGenericRecordStorage<XLCellFormatRecord>

extension XLCellFormatRecordsStorage {
    @discardableResult
    public func register(
        _ format: XLCellFormat,
        styles: XLStylesFile
    ) throws -> Int {
        try register(
            format,
            fonts: styles.fonts,
            fills: styles.fills,
            borders: styles.borders,
            cellStyleFormats: styles.cellStyleFormats
        )
    }

    @discardableResult
    public func register(
        _ format: XLCellFormat,
        fonts: XLFontRecordsStorage,
        fills: XLFillsStorage,
        borders: XLBordersStorage,
        cellStyleFormats: XLCellStyleFormatRefsStorage
    ) throws -> Int {
        try register(format.record(fonts: fonts, fills: fills, borders: borders, cellStyleFormats: cellStyleFormats))
    }
}
