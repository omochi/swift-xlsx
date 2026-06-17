import MemberwiseInit

@MemberwiseInit(.public)
public struct XLCellAddress: Sendable & Hashable & LosslessStringConvertible {
    public init?(_ description: String) {
        var column = 0
        var index = description.unicodeScalars.startIndex

        while index < description.unicodeScalars.endIndex {
            let scalar = description.unicodeScalars[index]
            guard let value = Self.columnValue(of: scalar) else {
                break
            }

            let (multipliedColumn, didMultiplyOverflow) = column.multipliedReportingOverflow(by: 26)
            let (nextColumn, didAddOverflow) = multipliedColumn.addingReportingOverflow(value)
            guard !didMultiplyOverflow, !didAddOverflow else {
                return nil
            }

            column = nextColumn
            index = description.unicodeScalars.index(after: index)
        }

        guard column > 0,
              index < description.unicodeScalars.endIndex
        else {
            return nil
        }

        var row = 0
        while index < description.unicodeScalars.endIndex {
            let scalar = description.unicodeScalars[index]
            guard let value = Self.rowValue(of: scalar) else {
                return nil
            }

            let (multipliedRow, didMultiplyOverflow) = row.multipliedReportingOverflow(by: 10)
            let (nextRow, didAddOverflow) = multipliedRow.addingReportingOverflow(value)
            guard !didMultiplyOverflow, !didAddOverflow else {
                return nil
            }

            row = nextRow
            index = description.unicodeScalars.index(after: index)
        }

        guard row > 0 else {
            return nil
        }

        self.row = row
        self.column = column
    }

    public var row: Int
    public var column: Int

    public var description: String {
        precondition(row > 0, "XLCellAddress row must be positive.")
        precondition(column > 0, "XLCellAddress column must be positive.")

        var remainingColumn = column
        var scalars: [UnicodeScalar] = []
        while remainingColumn > 0 {
            remainingColumn -= 1
            let scalar = UnicodeScalar(Self.uppercaseA + remainingColumn % 26)!
            scalars.append(scalar)
            remainingColumn /= 26
        }

        return String(String.UnicodeScalarView(scalars.reversed())) + String(row)
    }

    private static let uppercaseA = 65
    private static let uppercaseZ = 90
    private static let lowercaseA = 97
    private static let lowercaseZ = 122
    private static let zero = 48
    private static let nine = 57

    private static func columnValue(of scalar: UnicodeScalar) -> Int? {
        let value = Int(scalar.value)
        if uppercaseA...uppercaseZ ~= value {
            return value - uppercaseA + 1
        }
        if lowercaseA...lowercaseZ ~= value {
            return value - lowercaseA + 1
        }
        return nil
    }

    private static func rowValue(of scalar: UnicodeScalar) -> Int? {
        let value = Int(scalar.value)
        guard zero...nine ~= value else {
            return nil
        }
        return value - zero
    }
}
