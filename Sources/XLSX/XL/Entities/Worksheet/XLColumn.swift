import MemberwiseInit

@MemberwiseInit(.public)
public struct XLColumn {
    public var number: Int
    public var storage: XLColumnStorage

    public var width: Double? {
        get {
            storage.width
        }
        nonmutating set {
            storage.width = newValue
        }
    }

    public var format: XLCellFormat? {
        get {
            storage.format
        }
        nonmutating set {
            storage.format = newValue
        }
    }

    public var customWidth: Bool? {
        get {
            storage.customWidth
        }
        nonmutating set {
            storage.customWidth = newValue
        }
    }

    public var hidden: Bool? {
        get {
            storage.hidden
        }
        nonmutating set {
            storage.hidden = newValue
        }
    }

    public var bestFit: Bool? {
        get {
            storage.bestFit
        }
        nonmutating set {
            storage.bestFit = newValue
        }
    }

    public var outlineLevel: Int? {
        get {
            storage.outlineLevel
        }
        nonmutating set {
            storage.outlineLevel = newValue
        }
    }

    public var collapsed: Bool? {
        get {
            storage.collapsed
        }
        nonmutating set {
            storage.collapsed = newValue
        }
    }

    public var phonetic: Bool? {
        get {
            storage.phonetic
        }
        nonmutating set {
            storage.phonetic = newValue
        }
    }
}
