public struct XLCellFormatRecord: Sendable & Hashable {
    public init(
        numberFormatID: Int? = nil,
        fontID: Int? = nil,
        fillID: Int? = nil,
        borderID: Int? = nil,
        styleFormatID: Int? = nil,
        applyNumberFormat: Bool = false,
        applyFont: Bool = false,
        applyFill: Bool = false,
        applyBorder: Bool = false,
        applyAlignment: Bool = false,
        applyProtection: Bool = false
    ) {
        self.numberFormatID = numberFormatID
        self.fontID = fontID
        self.fillID = fillID
        self.borderID = borderID
        self.styleFormatID = styleFormatID
        self.applyNumberFormat = applyNumberFormat
        self.applyFont = applyFont
        self.applyFill = applyFill
        self.applyBorder = applyBorder
        self.applyAlignment = applyAlignment
        self.applyProtection = applyProtection
    }

    public init(element: XMLElement) {
        self.init(
            numberFormatID: XMLUtils.intAttribute(name: "numFmtId", in: element),
            fontID: XMLUtils.intAttribute(name: "fontId", in: element),
            fillID: XMLUtils.intAttribute(name: "fillId", in: element),
            borderID: XMLUtils.intAttribute(name: "borderId", in: element),
            styleFormatID: XMLUtils.intAttribute(name: "xfId", in: element),
            applyNumberFormat: XMLUtils.boolAttribute(name: "applyNumberFormat", in: element),
            applyFont: XMLUtils.boolAttribute(name: "applyFont", in: element),
            applyFill: XMLUtils.boolAttribute(name: "applyFill", in: element),
            applyBorder: XMLUtils.boolAttribute(name: "applyBorder", in: element),
            applyAlignment: XMLUtils.boolAttribute(name: "applyAlignment", in: element),
            applyProtection: XMLUtils.boolAttribute(name: "applyProtection", in: element)
        )
    }

    public var numberFormatID: Int?
    public var fontID: Int?
    public var fillID: Int?
    public var borderID: Int?
    public var styleFormatID: Int?
    public var applyNumberFormat: Bool
    public var applyFont: Bool
    public var applyFill: Bool
    public var applyBorder: Bool
    public var applyAlignment: Bool
    public var applyProtection: Bool

    public func xmlElement() -> XMLElement {
        let element = XMLElement(name: XMLName(name: "xf"))
        XMLUtils.setIntAttribute(name: "numFmtId", value: numberFormatID, in: element)
        XMLUtils.setIntAttribute(name: "fontId", value: fontID, in: element)
        XMLUtils.setIntAttribute(name: "fillId", value: fillID, in: element)
        XMLUtils.setIntAttribute(name: "borderId", value: borderID, in: element)
        XMLUtils.setIntAttribute(name: "xfId", value: styleFormatID, in: element)
        XMLUtils.setBoolAttribute(name: "applyNumberFormat", value: applyNumberFormat ? true : nil, in: element)
        XMLUtils.setBoolAttribute(name: "applyFont", value: applyFont ? true : nil, in: element)
        XMLUtils.setBoolAttribute(name: "applyFill", value: applyFill ? true : nil, in: element)
        XMLUtils.setBoolAttribute(name: "applyBorder", value: applyBorder ? true : nil, in: element)
        XMLUtils.setBoolAttribute(name: "applyAlignment", value: applyAlignment ? true : nil, in: element)
        XMLUtils.setBoolAttribute(name: "applyProtection", value: applyProtection ? true : nil, in: element)
        return element
    }
}
