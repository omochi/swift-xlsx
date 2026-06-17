public struct XLFontRecord: Sendable & Hashable {
    public init(
        bold: Bool = false,
        italic: Bool = false,
        strike: Bool = false,
        condense: Bool = false,
        extend: Bool = false,
        outline: Bool = false,
        shadow: Bool = false,
        underlineXMLString: String? = nil,
        verticalAlignmentXMLString: String? = nil,
        size: Double? = nil,
        color: XLColor? = nil,
        name: String? = nil,
        familyXMLString: String? = nil,
        charsetXMLString: String? = nil,
        schemeXMLString: String? = nil
    ) {
        self.bold = bold
        self.italic = italic
        self.strike = strike
        self.condense = condense
        self.extend = extend
        self.outline = outline
        self.shadow = shadow
        self.underlineXMLString = underlineXMLString
        self.verticalAlignmentXMLString = verticalAlignmentXMLString
        self.size = size
        self.color = color
        self.name = name
        self.familyXMLString = familyXMLString
        self.charsetXMLString = charsetXMLString
        self.schemeXMLString = schemeXMLString
    }

    public init(element: XMLElement) {
        self.init()

        for child in element.children {
            guard let childElement = child as? XMLElement else {
                continue
            }

            switch childElement.name.name {
            case "b":
                bold = Self.boolFontProperty(in: childElement)
            case "i":
                italic = Self.boolFontProperty(in: childElement)
            case "strike":
                strike = Self.boolFontProperty(in: childElement)
            case "condense":
                condense = Self.boolFontProperty(in: childElement)
            case "extend":
                extend = Self.boolFontProperty(in: childElement)
            case "outline":
                outline = Self.boolFontProperty(in: childElement)
            case "shadow":
                shadow = Self.boolFontProperty(in: childElement)
            case "u":
                underlineXMLString = childElement.xmlString
            case "vertAlign":
                verticalAlignmentXMLString = childElement.xmlString
            case "sz":
                size = XMLUtils.doubleAttribute(name: "val", in: childElement)
            case "color":
                color = XLColor(element: childElement)
            case "name":
                name = childElement.attribute(name: "val")
            case "family":
                familyXMLString = childElement.xmlString
            case "charset":
                charsetXMLString = childElement.xmlString
            case "scheme":
                schemeXMLString = childElement.xmlString
            default:
                break
            }
        }
    }

    public var bold: Bool
    public var italic: Bool
    public var strike: Bool
    public var condense: Bool
    public var extend: Bool
    public var outline: Bool
    public var shadow: Bool
    public var underlineXMLString: String?
    public var verticalAlignmentXMLString: String?
    public var size: Double?
    public var color: XLColor?
    public var name: String?
    public var familyXMLString: String?
    public var charsetXMLString: String?
    public var schemeXMLString: String?

    public func xmlElement() throws -> XMLElement {
        let element = XMLElement(name: XMLName(name: "font"))
        appendBoolFontProperty(name: "b", value: bold, to: element)
        appendBoolFontProperty(name: "i", value: italic, to: element)
        appendBoolFontProperty(name: "strike", value: strike, to: element)
        appendBoolFontProperty(name: "condense", value: condense, to: element)
        appendBoolFontProperty(name: "extend", value: extend, to: element)
        appendBoolFontProperty(name: "outline", value: outline, to: element)
        appendBoolFontProperty(name: "shadow", value: shadow, to: element)
        try appendElement(xmlString: underlineXMLString, to: element)
        try appendElement(xmlString: verticalAlignmentXMLString, to: element)
        appendFontSize(to: element)
        appendColor(to: element)
        appendFontName(to: element)
        try appendElement(xmlString: familyXMLString, to: element)
        try appendElement(xmlString: charsetXMLString, to: element)
        try appendElement(xmlString: schemeXMLString, to: element)
        return element
    }

    private static func boolFontProperty(in element: XMLElement) -> Bool {
        XMLUtils.boolAttribute(name: "val", in: element, defaultValue: true)
    }

    private func appendBoolFontProperty(name: String, value: Bool, to element: XMLElement) {
        guard value else {
            return
        }
        element.appendChild(XMLElement(name: XMLName(name: name)))
    }

    private func appendFontSize(to element: XMLElement) {
        guard let size else {
            return
        }
        let sizeElement = XMLElement(name: XMLName(name: "sz"))
        XMLUtils.setDoubleAttribute(name: "val", value: size, in: sizeElement)
        element.appendChild(sizeElement)
    }

    private func appendColor(to element: XMLElement) {
        guard let color else {
            return
        }
        element.appendChild(color.xmlElement(name: "color"))
    }

    private func appendFontName(to element: XMLElement) {
        guard name != nil else {
            return
        }
        let nameElement = XMLElement(name: XMLName(name: "name"))
        XMLUtils.setStringAttribute(name: "val", value: name, in: nameElement)
        element.appendChild(nameElement)
    }

    private func appendElement(xmlString: String?, to element: XMLElement) throws {
        guard let xmlString else {
            return
        }
        element.appendChild(try XMLElement(xmlString: xmlString))
    }
}
