import MemberwiseInit

@MemberwiseInit(.public)
public struct XLFormula: Sendable {
    public enum Kind: String, Sendable, Hashable {
        case normal
        case shared
        case array
        case dataTable
    }

    public init(record: XLFormulaRecord) {
        self.formula = record.formula
        self.kind = record.kind
        self.sharedIndex = record.sharedIndex
        self.reference = record.reference
        self.opaqueAttributes = record.opaqueAttributes
    }

    public var formula: String?
    public var kind: Kind = .normal
    public var sharedIndex: Int? = nil
    public var reference: XLCellRangeAddress? = nil
    public var opaqueAttributes: [XMLAttribute] = []

    public var record: XLFormulaRecord {
        XLFormulaRecord(
            formula: formula,
            kind: kind,
            sharedIndex: sharedIndex,
            reference: reference,
            opaqueAttributes: opaqueAttributes
        )
    }
}
