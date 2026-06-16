public struct XLCellFormatRecord: Sendable & Hashable {
    struct Storage: Hashable {
        var numberFormatID: Int?
        var fontID: Int?
        var fillID: Int?
        var borderID: Int?
        var formatID: Int?
        var applyNumberFormat: Bool
        var applyFont: Bool
        var applyFill: Bool
        var applyBorder: Bool
        var applyAlignment: Bool
        var applyProtection: Bool
    }

    public init(
        numberFormatID: Int? = nil,
        fontID: Int? = nil,
        fillID: Int? = nil,
        borderID: Int? = nil,
        formatID: Int? = nil,
        applyNumberFormat: Bool = false,
        applyFont: Bool = false,
        applyFill: Bool = false,
        applyBorder: Bool = false,
        applyAlignment: Bool = false,
        applyProtection: Bool = false
    ) {
        self.object = Box(
            Storage(
                numberFormatID: numberFormatID,
                fontID: fontID,
                fillID: fillID,
                borderID: borderID,
                formatID: formatID,
                applyNumberFormat: applyNumberFormat,
                applyFont: applyFont,
                applyFill: applyFill,
                applyBorder: applyBorder,
                applyAlignment: applyAlignment,
                applyProtection: applyProtection
            )
        )
    }

    init(element: XMLElement) {
        self.init(
            numberFormatID: Self.intAttribute(name: "numFmtId", in: element),
            fontID: Self.intAttribute(name: "fontId", in: element),
            fillID: Self.intAttribute(name: "fillId", in: element),
            borderID: Self.intAttribute(name: "borderId", in: element),
            formatID: Self.intAttribute(name: "xfId", in: element),
            applyNumberFormat: Self.boolAttribute(name: "applyNumberFormat", in: element),
            applyFont: Self.boolAttribute(name: "applyFont", in: element),
            applyFill: Self.boolAttribute(name: "applyFill", in: element),
            applyBorder: Self.boolAttribute(name: "applyBorder", in: element),
            applyAlignment: Self.boolAttribute(name: "applyAlignment", in: element),
            applyProtection: Self.boolAttribute(name: "applyProtection", in: element)
        )
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

    public static func == (lhs: XLCellFormatRecord, rhs: XLCellFormatRecord) -> Bool {
        lhs.storage == rhs.storage
    }

    public func hash(into hasher: inout Hasher) {
        storage.hash(into: &hasher)
    }

    public var numberFormatID: Int? {
        get { storage.numberFormatID }
        set {
            ensureUniqueObject()
            storage.numberFormatID = newValue
        }
    }

    public var fontID: Int? {
        get { storage.fontID }
        set {
            ensureUniqueObject()
            storage.fontID = newValue
        }
    }

    public var fillID: Int? {
        get { storage.fillID }
        set {
            ensureUniqueObject()
            storage.fillID = newValue
        }
    }

    public var borderID: Int? {
        get { storage.borderID }
        set {
            ensureUniqueObject()
            storage.borderID = newValue
        }
    }

    public var formatID: Int? {
        get { storage.formatID }
        set {
            ensureUniqueObject()
            storage.formatID = newValue
        }
    }

    public var applyNumberFormat: Bool {
        get { storage.applyNumberFormat }
        set {
            ensureUniqueObject()
            storage.applyNumberFormat = newValue
        }
    }

    public var applyFont: Bool {
        get { storage.applyFont }
        set {
            ensureUniqueObject()
            storage.applyFont = newValue
        }
    }

    public var applyFill: Bool {
        get { storage.applyFill }
        set {
            ensureUniqueObject()
            storage.applyFill = newValue
        }
    }

    public var applyBorder: Bool {
        get { storage.applyBorder }
        set {
            ensureUniqueObject()
            storage.applyBorder = newValue
        }
    }

    public var applyAlignment: Bool {
        get { storage.applyAlignment }
        set {
            ensureUniqueObject()
            storage.applyAlignment = newValue
        }
    }

    public var applyProtection: Bool {
        get { storage.applyProtection }
        set {
            ensureUniqueObject()
            storage.applyProtection = newValue
        }
    }

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
