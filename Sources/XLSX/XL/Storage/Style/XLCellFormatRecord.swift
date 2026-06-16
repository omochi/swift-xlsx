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
            numberFormatID: XMLUtils.intAttribute(name: "numFmtId", in: element),
            fontID: XMLUtils.intAttribute(name: "fontId", in: element),
            fillID: XMLUtils.intAttribute(name: "fillId", in: element),
            borderID: XMLUtils.intAttribute(name: "borderId", in: element),
            formatID: XMLUtils.intAttribute(name: "xfId", in: element),
            applyNumberFormat: XMLUtils.boolAttribute(name: "applyNumberFormat", in: element),
            applyFont: XMLUtils.boolAttribute(name: "applyFont", in: element),
            applyFill: XMLUtils.boolAttribute(name: "applyFill", in: element),
            applyBorder: XMLUtils.boolAttribute(name: "applyBorder", in: element),
            applyAlignment: XMLUtils.boolAttribute(name: "applyAlignment", in: element),
            applyProtection: XMLUtils.boolAttribute(name: "applyProtection", in: element)
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
        XMLUtils.setIntAttribute(name: "numFmtId", value: numberFormatID, in: element)
        XMLUtils.setIntAttribute(name: "fontId", value: fontID, in: element)
        XMLUtils.setIntAttribute(name: "fillId", value: fillID, in: element)
        XMLUtils.setIntAttribute(name: "borderId", value: borderID, in: element)
        XMLUtils.setIntAttribute(name: "xfId", value: formatID, in: element)
        XMLUtils.setBoolAttribute(name: "applyNumberFormat", value: applyNumberFormat ? true : nil, in: element)
        XMLUtils.setBoolAttribute(name: "applyFont", value: applyFont ? true : nil, in: element)
        XMLUtils.setBoolAttribute(name: "applyFill", value: applyFill ? true : nil, in: element)
        XMLUtils.setBoolAttribute(name: "applyBorder", value: applyBorder ? true : nil, in: element)
        XMLUtils.setBoolAttribute(name: "applyAlignment", value: applyAlignment ? true : nil, in: element)
        XMLUtils.setBoolAttribute(name: "applyProtection", value: applyProtection ? true : nil, in: element)
        return element
    }
}
