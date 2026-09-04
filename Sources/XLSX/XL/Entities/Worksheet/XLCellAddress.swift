import MemberwiseInit

@MemberwiseInit(.public)
public struct XLCellAddress: Sendable & Hashable & LosslessStringConvertible {
    public init?(_ description: String) {
        var isColumnAbsolute = false
        var index = description.unicodeScalars.startIndex

        if index < description.unicodeScalars.endIndex,
           description.unicodeScalars[index] == Self.dollar
        {
            isColumnAbsolute = true
            index = description.unicodeScalars.index(after: index)
        }

        let columnStartIndex = index
        while index < description.unicodeScalars.endIndex {
            let scalar = description.unicodeScalars[index]
            guard Self.columnDigitValue(of: scalar) != nil else {
                break
            }

            index = description.unicodeScalars.index(after: index)
        }

        let columnText = String(description.unicodeScalars[columnStartIndex..<index])
        guard let column = Self.columnValue(string: columnText),
              index < description.unicodeScalars.endIndex
        else {
            return nil
        }

        var isRowAbsolute = false
        if description.unicodeScalars[index] == Self.dollar {
            isRowAbsolute = true
            index = description.unicodeScalars.index(after: index)
        }

        guard index < description.unicodeScalars.endIndex else {
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

        self.isRowAbsolute = isRowAbsolute
        self.row = row
        self.isColumnAbsolute = isColumnAbsolute
        self.column = column
    }

    public var isRowAbsolute: Bool = false
    public var row: Int
    public var isColumnAbsolute: Bool = false
    public var column: Int

    public static var maxRowNumber: Int {
        1_048_576
    }

    public static var maxColumnNumber: Int {
        16_384
    }

    public var description: String {
        precondition(row > 0, "XLCellAddress row must be positive.")
        precondition(column > 0, "XLCellAddress column must be positive.")

        return "\(isColumnAbsolute ? "$" : "")\(Self.columnString(column))\(isRowAbsolute ? "$" : "")\(row)"
    }

    public static func columnString(_ column: Int) -> String {
        precondition(column > 0, "XLCellAddress column must be positive.")

        var remainingColumn = column
        var scalars: [UnicodeScalar] = []
        while remainingColumn > 0 {
            remainingColumn -= 1
            let scalar = UnicodeScalar(Self.uppercaseA + remainingColumn % 26)!
            scalars.append(scalar)
            remainingColumn /= 26
        }

        return String(String.UnicodeScalarView(scalars.reversed()))
    }

    public static func columnValue(string: String) -> Int? {
        var column = 0
        for scalar in string.unicodeScalars {
            guard let value = Self.columnDigitValue(of: scalar) else {
                return nil
            }

            let (multipliedColumn, didMultiplyOverflow) = column.multipliedReportingOverflow(by: 26)
            let (nextColumn, didAddOverflow) = multipliedColumn.addingReportingOverflow(value)
            guard !didMultiplyOverflow, !didAddOverflow else {
                return nil
            }

            column = nextColumn
        }

        guard column > 0 else {
            return nil
        }
        return column
    }

    private static let dollar = UnicodeScalar(36)!
    private static let uppercaseA = 65
    private static let uppercaseZ = 90
    private static let lowercaseA = 97
    private static let lowercaseZ = 122
    private static let zero = 48
    private static let nine = 57

    private static func columnDigitValue(of scalar: UnicodeScalar) -> Int? {
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
