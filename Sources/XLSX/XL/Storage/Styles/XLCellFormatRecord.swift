import MemberwiseInit

@MemberwiseInit(.public)
public struct XLCellFormatRecord: Sendable & Hashable {
    init(element: XMLElement) {
        self.numberFormatID = Self.intAttribute(name: "numFmtId", in: element)
        self.fontID = Self.intAttribute(name: "fontId", in: element)
        self.fillID = Self.intAttribute(name: "fillId", in: element)
        self.borderID = Self.intAttribute(name: "borderId", in: element)
        self.formatID = Self.intAttribute(name: "xfId", in: element)
        self.applyNumberFormat = Self.boolAttribute(name: "applyNumberFormat", in: element)
        self.applyFont = Self.boolAttribute(name: "applyFont", in: element)
        self.applyFill = Self.boolAttribute(name: "applyFill", in: element)
        self.applyBorder = Self.boolAttribute(name: "applyBorder", in: element)
        self.applyAlignment = Self.boolAttribute(name: "applyAlignment", in: element)
        self.applyProtection = Self.boolAttribute(name: "applyProtection", in: element)
    }

    public var numberFormatID: Int? = nil
    public var fontID: Int? = nil
    public var fillID: Int? = nil
    public var borderID: Int? = nil
    public var formatID: Int? = nil
    public var applyNumberFormat = false
    public var applyFont = false
    public var applyFill = false
    public var applyBorder = false
    public var applyAlignment = false
    public var applyProtection = false

    func xmlElement() -> XMLElement {
        let element = XMLElement(name: XMLName(name: "xf"))
        Self.setAttribute(name: "numFmtId", value: numberFormatID, in: element)
        Self.setAttribute(name: "fontId", value: fontID, in: element)
        Self.setAttribute(name: "fillId", value: fillID, in: element)
        Self.setAttribute(name: "borderId", value: borderID, in: element)
        Self.setAttribute(name: "xfId", value: formatID, in: element)
        Self.setAttribute(name: "applyNumberFormat", value: applyNumberFormat, in: element)
        Self.setAttribute(name: "applyFont", value: applyFont, in: element)
        Self.setAttribute(name: "applyFill", value: applyFill, in: element)
        Self.setAttribute(name: "applyBorder", value: applyBorder, in: element)
        Self.setAttribute(name: "applyAlignment", value: applyAlignment, in: element)
        Self.setAttribute(name: "applyProtection", value: applyProtection, in: element)
        return element
    }

    private static func intAttribute(name: String, in element: XMLElement) -> Int? {
        guard let value = element.attribute(name: name) else {
            return nil
        }
        return Int(value)
    }

    private static func boolAttribute(name: String, in element: XMLElement) -> Bool {
        guard let value = element.attribute(name: name) else {
            return false
        }
        return XLCellValue.readBool(string: value) ?? false
    }

    private static func setAttribute(name: String, value: Int?, in element: XMLElement) {
        guard let value else {
            return
        }
        element.setAttribute(name: name, value: String(value))
    }

    private static func setAttribute(name: String, value: Bool, in element: XMLElement) {
        guard value else {
            return
        }
        element.setAttribute(name: name, value: XLCellValue.boolean(true).description)
    }
}
