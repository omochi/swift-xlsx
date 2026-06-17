import MemberwiseInit

public enum XLFill: Sendable & Hashable {
    @MemberwiseInit(.public)
    public struct Pattern: Sendable & Hashable {
        public var patternType: String? = nil
        public var foregroundColor: XLColor? = nil
        public var backgroundColor: XLColor? = nil

        public static var none: Self {
            Self(patternType: "none")
        }

        public static var gray125: Self {
            Self(patternType: "gray125")
        }

        init(element: XMLElement) {
            self.init(
                patternType: element.attribute(name: "patternType"),
                foregroundColor: element.elements(name: "fgColor").first.flatMap(XLColor.init(element:)),
                backgroundColor: element.elements(name: "bgColor").first.flatMap(XLColor.init(element:))
            )
        }

        func xmlElement() -> XMLElement {
            let element = XMLElement(name: XMLName(name: "patternFill"))
            XMLUtils.setStringAttribute(name: "patternType", value: patternType, in: element)

            if let foregroundColor {
                element.appendChild(foregroundColor.xmlElement(name: "fgColor"))
            }
            if let backgroundColor {
                element.appendChild(backgroundColor.xmlElement(name: "bgColor"))
            }

            return element
        }
    }

    case pattern(Pattern)
    case gradient(xmlString: String)

    init(element: XMLElement) {
        if let patternElement = element.elements(name: "patternFill").first {
            self = .pattern(Pattern(element: patternElement))
        } else if let gradientElement = element.elements(name: "gradientFill").first {
            self = .gradient(xmlString: gradientElement.xmlString)
        } else {
            self = .pattern(Pattern())
        }
    }

    func xmlElement() throws -> XMLElement {
        let element = XMLElement(name: XMLName(name: "fill"))

        switch self {
        case let .pattern(pattern):
            element.appendChild(pattern.xmlElement())
        case let .gradient(xmlString):
            element.appendChild(try XMLElement(xmlString: xmlString))
        }

        return element
    }
}
