import Foundation

public final class XLCellStorage {
    public init(
        value: XLCellValue,
        format: XLCellFormat? = nil,
        formula: XLFormula? = nil
    ) {
        self.value = value
        self.format = format
        self.formula = formula
    }

    public init?(
        cellElement: XMLElement,
        sharedStringStorage: XLSharedStringRecordsStorage,
        styleStorage: XLStyleStorage,
        sharedFormulaDefinitionAddressByIndex: [Int: XLCellAddress] = [:]
    ) {
        guard let value = XLCellValue(
            cellElement: cellElement,
            sharedStringStorage: sharedStringStorage
        ) else {
            return nil
        }

        self.value = value
        self.format = Self.format(
            in: cellElement,
            styleStorage: styleStorage
        )
        self.formula = Self.formula(
            in: cellElement,
            sharedFormulaDefinitionAddressByIndex: sharedFormulaDefinitionAddressByIndex
        )
    }

    public var value: XLCellValue
    public var format: XLCellFormat?
    public var formula: XLFormula?

    public func write(
        to cellElement: XMLElement,
        address: XLCellAddress? = nil,
        sharedStringStorage: XLSharedStringRecordsStorage? = nil,
        styleStorage: XLStyleStorage? = nil,
        formulaSharedIndicesByDefinitionAddress: [XLCellAddress: Int]? = nil
    ) throws {
        try writeFormat(to: cellElement, styleStorage: styleStorage)

        cellElement.children = cellElement.children.filter { child in
            guard let element = child as? XMLElement else {
                return true
            }
            return element.name.name != "f" && element.name.name != "v" && element.name.name != "is"
        }

        var didWriteFormula = false
        if let formula {
            let record = self.formulaRecord(
                for: formula,
                address: address,
                sharedIndicesByDefinitionAddress: formulaSharedIndicesByDefinitionAddress
            )
            if let record {
                cellElement.appendChild(record.xmlElement())
                didWriteFormula = true
            }
        }

        try writeValue(
            to: cellElement,
            sharedStringStorage: sharedStringStorage,
            hasFormula: didWriteFormula
        )
    }

    public func collectSharedStrings(sharedStringStorage: inout XLSharedStringRecordsStorage) {
        if let formula,
           formula.kind != .sharedReference,
           case .string = value
        {
            return
        }

        collectValueSharedStrings(sharedStringStorage: &sharedStringStorage)
    }

    public func collectSharedStrings(
        sharedStringStorage: inout XLSharedStringRecordsStorage,
        address: XLCellAddress,
        formulaSharedIndicesByDefinitionAddress: [XLCellAddress: Int]
    ) {
        if let formula,
           case .string = value,
           willWriteFormula(
               formula,
               address: address,
               sharedIndicesByDefinitionAddress: formulaSharedIndicesByDefinitionAddress
           )
        {
            return
        }

        collectValueSharedStrings(sharedStringStorage: &sharedStringStorage)
    }

    private func collectValueSharedStrings(sharedStringStorage: inout XLSharedStringRecordsStorage) {
        switch value {
        case let .string(text):
            sharedStringStorage.register(text)
        case let .opaqueSharedString(xmlString):
            sharedStringStorage.register(.opaque(xmlString: xmlString))
        case .number, .boolean, .error:
            break
        }
    }

    public func collectStyle(stage: XLStyleCollectionStage, styleStorage: inout XLStyleStorage) throws {
        try format?.collectStyle(stage: stage, styleStorage: &styleStorage)
    }

    public func clone() -> XLCellStorage {
        XLCellStorage(value: value, format: format, formula: formula)
    }

    private static func formatIndex(in cellElement: XMLElement) -> Int? {
        guard let value = cellElement.attribute(name: "s") else {
            return nil
        }
        return Int(value)
    }

    private static func format(
        in cellElement: XMLElement,
        styleStorage: XLStyleStorage
    ) -> XLCellFormat? {
        guard let formatIndex = formatIndex(in: cellElement) else {
            return nil
        }

        guard let record = styleStorage.cellFormats.record(at: formatIndex) else {
            return nil
        }

        return XLCellFormat(
            record: record,
            numberFormats: styleStorage.numberFormats,
            fonts: styleStorage.fonts,
            fills: styleStorage.fills,
            borders: styleStorage.borders,
            cellStyleFormats: styleStorage.cellStyleFormats
        )
    }

    private static func formula(
        in cellElement: XMLElement,
        sharedFormulaDefinitionAddressByIndex: [Int: XLCellAddress]
    ) -> XLFormula? {
        guard let formulaElement = cellElement.elements(name: "f").first else {
            return nil
        }

        return XLFormula(
            record: XLFormulaRecord(formulaElement: formulaElement),
            sharedFormulaDefinitionAddressByIndex: sharedFormulaDefinitionAddressByIndex
        )
    }

    private func writeFormat(
        to cellElement: XMLElement,
        styleStorage: XLStyleStorage?
    ) throws {
        guard let format,
              let styleStorage
        else {
            removeAttribute(name: "s", in: cellElement)
            return
        }

        let formatRecord = try format.record(styleStorage: styleStorage)
        cellElement.setAttribute(
            name: "s",
            value: styleStorage.cellFormats.index(for: formatRecord).map(String.init)
        )
    }

    private func writeValue(
        to cellElement: XMLElement,
        sharedStringStorage: XLSharedStringRecordsStorage?,
        hasFormula: Bool
    ) throws {
        if hasFormula,
           case let .string(text) = value
        {
            cellElement.setAttribute(name: "t", value: "str")
            appendValueElement(to: cellElement, text: text)
            return
        }

        try value.write(to: cellElement, sharedStrings: sharedStringStorage)
    }

    private func formulaRecord(
        for formula: XLFormula,
        address: XLCellAddress?,
        sharedIndicesByDefinitionAddress: [XLCellAddress: Int]?
    ) -> XLFormulaRecord? {
        switch formula {
        case let .regular(formula):
            return XLFormulaRecord(formula: formula)
        case let .sharedDefinition(definition):
            return XLFormulaRecord(
                formula: definition.formula,
                kind: .shared,
                sharedIndex: address.flatMap { sharedIndicesByDefinitionAddress?[$0] },
                reference: definition.reference
            )
        case let .sharedReference(address):
            guard let sharedIndex = sharedIndicesByDefinitionAddress?[address] else {
                return nil
            }

            return XLFormulaRecord(
                formula: nil,
                kind: .shared,
                sharedIndex: sharedIndex
            )
        case let .array(xmlString), let .dataTable(xmlString):
            guard let element = try? XMLElement(xmlString: xmlString),
                  element.name.name == "f"
            else {
                return nil
            }
            return XLFormulaRecord(formulaElement: element)
        }
    }

    private func willWriteFormula(
        _ formula: XLFormula,
        address: XLCellAddress,
        sharedIndicesByDefinitionAddress: [XLCellAddress: Int]
    ) -> Bool {
        switch formula {
        case .regular, .array, .dataTable:
            return true
        case .sharedDefinition:
            return sharedIndicesByDefinitionAddress[address] != nil
        case let .sharedReference(address):
            return sharedIndicesByDefinitionAddress[address] != nil
        }
    }

    private func appendValueElement(to cellElement: XMLElement, text: String) {
        let valueElement = XMLElement(name: XMLName(name: "v"))
        valueElement.appendChild(XMLText(text))
        cellElement.appendChild(valueElement)
    }

    private func removeAttribute(name: String, in cellElement: XMLElement) {
        cellElement.attributes.removeAll { $0.name.prefix == nil && $0.name.name == name }
    }
}
