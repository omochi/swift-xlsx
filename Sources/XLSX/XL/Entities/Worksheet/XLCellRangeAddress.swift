public struct XLCellRangeAddress: Sendable, Hashable, LosslessStringConvertible {
    public init?(_ description: String) {
        let parts = description.split(separator: ":", omittingEmptySubsequences: false)
        guard parts.count == 1 || parts.count == 2,
              let start = XLCellAddress(String(parts[0]))
        else {
            return nil
        }

        if parts.count == 1 {
            self.start = start
            self.last = start
            return
        }

        guard let last = XLCellAddress(String(parts[1])) else {
            return nil
        }

        self.start = start
        self.last = last
    }

    public init(start: XLCellAddress, last: XLCellAddress) {
        self.start = start
        self.last = last
    }

    public init(start: XLCellAddress, end: XLCellAddress) {
        self.start = start
        self.last = XLCellAddress(row: end.row - 1, column: end.column - 1)
    }

    public var start: XLCellAddress
    public var last: XLCellAddress

    public var end: XLCellAddress {
        get {
            return XLCellAddress(row: last.row + 1, column: last.column + 1)
        }
        set {
            last = XLCellAddress(row: newValue.row - 1, column: newValue.column - 1)
        }
    }

    public var description: String {
        if start == last {
            return start.description
        }

        return "\(start):\(last)"
    }
}
