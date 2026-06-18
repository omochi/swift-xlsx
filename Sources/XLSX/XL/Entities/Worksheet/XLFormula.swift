public enum XLFormula: Sendable {
    public enum Kind: String, Sendable & Hashable {
        case regular
        case sharedDefinition
        case sharedReference
        case array
        case dataTable
    }

    public var kind: Kind {
        switch self {
        case .regular:
            return .regular
        case .sharedDefinition:
            return .sharedDefinition
        case .sharedReference:
            return .sharedReference
        case .array:
            return .array
        case .dataTable:
            return .dataTable
        }
    }

    public init?(
        record: XLFormulaRecord,
        sharedFormulaDefinitionAddressByIndex: [Int: XLCellAddress] = [:]
    ) {
        switch record.kind {
        case .normal:
            self = .regular(record.formula ?? "")
        case .shared:
            if let formula = record.formula {
                self = .sharedDefinition(XLSharedFormulaDefinition(
                    formula: formula,
                    reference: record.reference
                ))
            } else if let sharedIndex = record.sharedIndex,
                      let address = sharedFormulaDefinitionAddressByIndex[sharedIndex]
            {
                self = .sharedReference(address: address)
            } else {
                return nil
            }
        case .array:
            self = .array(xmlString: record.xmlElement().xmlString())
        case .dataTable:
            self = .dataTable(xmlString: record.xmlElement().xmlString())
        }
    }

    case regular(String)
    case sharedDefinition(XLSharedFormulaDefinition)
    case sharedReference(address: XLCellAddress)
    case array(xmlString: String)
    case dataTable(xmlString: String)
}
