import XLSXXML

public struct XLCellFormatProtection: Sendable & Hashable {
    public init(locked: Bool = true, hidden: Bool = false) {
        self.locked = locked
        self.hidden = hidden
    }

    public init(element: XMLElement) {
        self.init(
            locked: XMLUtils.boolAttribute(name: "locked", in: element, defaultValue: true),
            hidden: XMLUtils.boolAttribute(name: "hidden", in: element)
        )
    }

    public var locked: Bool = true
    public var hidden: Bool = false

    public func xmlElement() -> XMLElement {
        let element = XMLElement(name: XMLName(name: "protection"))
        XMLUtils.setBoolAttribute(name: "locked", value: locked ? nil : false, in: element)
        XMLUtils.setBoolAttribute(name: "hidden", value: hidden ? true : nil, in: element)
        return element
    }
}
