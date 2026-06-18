import MemberwiseInit

@MemberwiseInit(.public)
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
            self.end = start
            return
        }

        guard let end = XLCellAddress(String(parts[1])) else {
            return nil
        }

        self.start = start
        self.end = end
    }

    public var start: XLCellAddress
    public var end: XLCellAddress

    public var description: String {
        if start == end {
            return start.description
        }

        return "\(start):\(end)"
    }
}
