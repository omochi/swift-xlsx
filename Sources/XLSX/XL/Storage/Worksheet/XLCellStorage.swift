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
        sharedStrings: XLSharedStringsFile,
        styles: XLStylesFile
    ) {
        guard let value = XLCellValue(
            cellElement: cellElement,
            sharedStrings: sharedStrings
        ) else {
            return nil
        }

        self.value = value
        self.format = Self.format(
            in: cellElement,
            styles: styles
        )
        self.formula = Self.formula(in: cellElement)
    }

    public var value: XLCellValue
    public var format: XLCellFormat?
    public var formula: XLFormula?

    public func write(
        to cellElement: XMLElement,
        sharedStrings: XLSharedStringsFile? = nil,
        styles: XLStylesFile? = nil
    ) throws {
        try writeFormat(to: cellElement, styles: styles)

        cellElement.children = cellElement.children.filter { child in
            guard let element = child as? XMLElement else {
                return true
            }
            return element.name.name != "f" && element.name.name != "v" && element.name.name != "is"
        }

        if let formula {
            cellElement.appendChild(formula.record.xmlElement())
        }

        try writeValue(to: cellElement, sharedStrings: sharedStrings)
    }

    public func collectSharedStrings(sharedStrings: XLSharedStringsFile) {
        if formula != nil,
           case .string = value
        {
            return
        }

        switch value {
        case let .string(text):
            sharedStrings.records.register(text)
        case let .opaqueSharedString(xmlString):
            sharedStrings.records.register(.opaque(xmlString: xmlString))
        case .number, .boolean, .error:
            break
        }
    }

    public func collectStyle(stage: XLStyleCollectionStage, styles: XLStylesFile) throws {
        try format?.collectStyle(stage: stage, styles: styles)
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
        styles: XLStylesFile
    ) -> XLCellFormat? {
        guard let formatIndex = formatIndex(in: cellElement) else {
            return nil
        }

        guard let record = styles.cellFormats.record(at: formatIndex) else {
            return nil
        }

        return XLCellFormat(
            record: record,
            numberFormats: styles.numberFormats,
            fonts: styles.fonts,
            fills: styles.fills,
            borders: styles.borders,
            cellStyleFormats: styles.cellStyleFormats
        )
    }

    private static func formula(in cellElement: XMLElement) -> XLFormula? {
        guard let formulaElement = cellElement.elements(name: "f").first else {
            return nil
        }

        return XLFormula(record: XLFormulaRecord(formulaElement: formulaElement))
    }

    private func writeFormat(
        to cellElement: XMLElement,
        styles: XLStylesFile?
    ) throws {
        guard let format,
              let styles
        else {
            removeAttribute(name: "s", in: cellElement)
            return
        }

        let formatRecord = try format.record(styles: styles)
        cellElement.setAttribute(
            name: "s",
            value: styles.cellFormats.index(for: formatRecord).map(String.init)
        )
    }

    private func writeValue(
        to cellElement: XMLElement,
        sharedStrings: XLSharedStringsFile?
    ) throws {
        if formula != nil,
           case let .string(text) = value
        {
            cellElement.setAttribute(name: "t", value: "str")
            appendValueElement(to: cellElement, text: text)
            return
        }

        try value.write(to: cellElement, sharedStrings: sharedStrings?.records)
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
