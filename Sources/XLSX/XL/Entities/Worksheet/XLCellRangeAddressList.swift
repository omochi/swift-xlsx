public struct XLCellRangeAddressList: Sendable & Hashable & LosslessStringConvertible {
    public init(_ ranges: [XLCellRangeAddress]) {
        self.ranges = ranges
    }

    public init?(_ description: String) {
        let rangeTexts = description.split(whereSeparator: \.isWhitespace)
        guard !rangeTexts.isEmpty else {
            return nil
        }

        var ranges: [XLCellRangeAddress] = []
        for rangeText in rangeTexts {
            guard let range = XLCellRangeAddress(String(rangeText)) else {
                return nil
            }
            ranges.append(range)
        }

        self.ranges = ranges
    }

    public var ranges: [XLCellRangeAddress]

    public var description: String {
        ranges.map(\.description).joined(separator: " ")
    }
}
