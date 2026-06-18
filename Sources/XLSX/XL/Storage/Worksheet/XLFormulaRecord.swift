import MemberwiseInit

@MemberwiseInit(.public)
public struct XLFormulaRecord: Sendable {
    public enum Kind: String, Sendable & Hashable {
        case normal
        case shared
        case array
        case dataTable
    }

    public init(formulaElement: XMLElement) {
        self.formula = Self.formula(in: formulaElement)
        self.kind = formulaElement.attribute(name: "t").flatMap(Kind.init(rawValue:)) ?? .normal
        self.sharedIndex = XMLUtils.intAttribute(name: "si", in: formulaElement)
        self.reference = formulaElement.attribute(name: "ref").flatMap(XLCellRangeAddress.init)
        self.opaqueAttributes = formulaElement.attributes.filter { !Self.isKnownAttribute($0) }
    }

    public var formula: String?
    public var kind: Kind = .normal
    public var sharedIndex: Int? = nil
    public var reference: XLCellRangeAddress? = nil
    public var opaqueAttributes: [XMLAttribute] = []

    public func xmlElement() -> XMLElement {
        let element = XMLElement(name: XMLName(name: "f"))
        write(to: element)
        return element
    }

    public func write(to formulaElement: XMLElement) {
        formulaElement.attributes = opaqueAttributes
        formulaElement.children = formula.map { [XMLText($0) as XMLNode] } ?? []
        formulaElement.setAttribute(name: "t", value: kind.rawValue)
        XMLUtils.setIntAttribute(name: "si", value: sharedIndex, in: formulaElement)
        formulaElement.setAttribute(name: "ref", value: reference?.description)
    }

    private static func formula(in formulaElement: XMLElement) -> String? {
        let text = formulaElement.children.compactMap { ($0 as? XMLText)?.value }.joined()
        return text.isEmpty ? nil : text
    }

    private static func isKnownAttribute(_ attribute: XMLAttribute) -> Bool {
        attribute.name.prefix == nil && ["t", "si", "ref"].contains(attribute.name.name)
    }
}
