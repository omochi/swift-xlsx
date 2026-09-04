import XLSXXML

public enum XLColor: Sendable & Hashable {
    case rgb(String)
    case indexed(Int)
    case theme(Int, tint: Double? = nil)
    case auto

    public init?(element: XMLElement) {
        if let rgb = element.attribute(name: "rgb") {
            self = .rgb(rgb)
            return
        }

        if let indexed = XMLUtils.intAttribute(name: "indexed", in: element) {
            self = .indexed(indexed)
            return
        }

        if let theme = XMLUtils.intAttribute(name: "theme", in: element) {
            self = .theme(theme, tint: XMLUtils.doubleAttribute(name: "tint", in: element))
            return
        }

        if XMLUtils.boolAttribute(name: "auto", in: element) {
            self = .auto
            return
        }

        return nil
    }

    public func xmlElement(name: String) -> XMLElement {
        let element = XMLElement(name: XMLName(name: name))

        switch self {
        case .rgb(let value):
            element.setAttribute(name: "rgb", value: value)
        case .indexed(let value):
            XMLUtils.setIntAttribute(name: "indexed", value: value, in: element)
        case .theme(let value, let tint):
            XMLUtils.setIntAttribute(name: "theme", value: value, in: element)
            XMLUtils.setDoubleAttribute(name: "tint", value: tint, in: element)
        case .auto:
            XMLUtils.setBoolAttribute(name: "auto", value: true, in: element)
        }

        return element
    }
}
