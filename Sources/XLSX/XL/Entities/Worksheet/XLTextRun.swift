import MemberwiseInit
import XLSXXML

@MemberwiseInit(.public)
public struct XLTextRun: Sendable & Hashable {
    public init(element: XMLElement) {
        var text = ""
        var font: XLFont?

        for child in element.children {
            guard let childElement = child as? XMLElement else { continue }

            switch childElement.name.name {
            case "rPr": font = XLFont(element: childElement)
            case "t": text = XLText.textContent(in: childElement)
            default: continue
            }
        }

        self.text = text
        self.font = font
    }

    public var text: String
    public var font: XLFont? = nil

    public func xmlElement() throws -> XMLElement {
        let element = XMLElement(name: XMLName(name: "r"))
        if let font {
            element.appendChild(try font.xmlElement(name: "rPr", fontNameElementName: "rFont"))
        }
        element.appendChild(XLText.textElement(text))
        return element
    }
}
