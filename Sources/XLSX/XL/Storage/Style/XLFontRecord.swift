public struct XLFontRecord: Sendable & Hashable {
    struct Storage: Hashable {
        var bold: Bool
        var italic: Bool
        var strike: Bool
        var condense: Bool
        var extend: Bool
        var outline: Bool
        var shadow: Bool
        var underlineXMLString: String?
        var verticalAlignmentXMLString: String?
        var size: Double?
        var color: XLColor?
        var name: String?
        var familyXMLString: String?
        var charsetXMLString: String?
        var schemeXMLString: String?
    }

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
        self.object = Box(
            Storage(
                bold: bold,
                italic: italic,
                strike: strike,
                condense: condense,
                extend: extend,
                outline: outline,
                shadow: shadow,
                underlineXMLString: underlineXMLString,
                verticalAlignmentXMLString: verticalAlignmentXMLString,
                size: size,
                color: color,
                name: name,
                familyXMLString: familyXMLString,
                charsetXMLString: charsetXMLString,
                schemeXMLString: schemeXMLString
            )
        )
    }

    init(element: XMLElement) {
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

    private nonisolated(unsafe) var object: Box<Storage>

    private var storage: Storage {
        _read {
            yield object.value
        }
        _modify {
            yield &object.value
        }
    }

    private mutating func ensureUniqueObject() {
        if !isKnownUniquelyReferenced(&object) {
            object = Box(storage)
        }
    }

    public static func == (lhs: XLFontRecord, rhs: XLFontRecord) -> Bool {
        lhs.storage == rhs.storage
    }

    public func hash(into hasher: inout Hasher) {
        storage.hash(into: &hasher)
    }

    public var bold: Bool {
        get { storage.bold }
        set {
            ensureUniqueObject()
            storage.bold = newValue
        }
    }

    public var italic: Bool {
        get { storage.italic }
        set {
            ensureUniqueObject()
            storage.italic = newValue
        }
    }

    public var strike: Bool {
        get { storage.strike }
        set {
            ensureUniqueObject()
            storage.strike = newValue
        }
    }

    public var condense: Bool {
        get { storage.condense }
        set {
            ensureUniqueObject()
            storage.condense = newValue
        }
    }

    public var extend: Bool {
        get { storage.extend }
        set {
            ensureUniqueObject()
            storage.extend = newValue
        }
    }

    public var outline: Bool {
        get { storage.outline }
        set {
            ensureUniqueObject()
            storage.outline = newValue
        }
    }

    public var shadow: Bool {
        get { storage.shadow }
        set {
            ensureUniqueObject()
            storage.shadow = newValue
        }
    }

    public var underlineXMLString: String? {
        get { storage.underlineXMLString }
        set {
            ensureUniqueObject()
            storage.underlineXMLString = newValue
        }
    }

    public var verticalAlignmentXMLString: String? {
        get { storage.verticalAlignmentXMLString }
        set {
            ensureUniqueObject()
            storage.verticalAlignmentXMLString = newValue
        }
    }

    public var size: Double? {
        get { storage.size }
        set {
            ensureUniqueObject()
            storage.size = newValue
        }
    }

    public var color: XLColor? {
        get { storage.color }
        set {
            ensureUniqueObject()
            storage.color = newValue
        }
    }

    public var name: String? {
        get { storage.name }
        set {
            ensureUniqueObject()
            storage.name = newValue
        }
    }

    public var familyXMLString: String? {
        get { storage.familyXMLString }
        set {
            ensureUniqueObject()
            storage.familyXMLString = newValue
        }
    }

    public var charsetXMLString: String? {
        get { storage.charsetXMLString }
        set {
            ensureUniqueObject()
            storage.charsetXMLString = newValue
        }
    }

    public var schemeXMLString: String? {
        get { storage.schemeXMLString }
        set {
            ensureUniqueObject()
            storage.schemeXMLString = newValue
        }
    }

    func xmlElement() throws -> XMLElement {
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
