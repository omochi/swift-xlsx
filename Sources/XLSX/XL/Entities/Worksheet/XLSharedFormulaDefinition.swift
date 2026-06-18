import MemberwiseInit

@MemberwiseInit(.public)
public struct XLSharedFormulaDefinition: Sendable {
    public var formula: String
    public var reference: XLCellRangeAddress? = nil
}
