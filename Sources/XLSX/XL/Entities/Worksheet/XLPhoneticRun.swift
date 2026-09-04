import MemberwiseInit
import XLSXXML

@MemberwiseInit(.public)
public struct XLPhoneticRun: Sendable & Hashable {
    public init(element: XMLElement) {
        self.text = element.elements(name: "t").first.map(XLText.textContent) ?? ""
        self.startIndex = XMLUtils.intAttribute(name: "sb", in: element)
        self.endIndex = XMLUtils.intAttribute(name: "eb", in: element)
    }

    public var text: String
    public var startIndex: Int? = nil
    public var endIndex: Int? = nil

    public func xmlElement() -> XMLElement {
        let element = XMLElement(name: XMLName(name: "rPh"))
        XMLUtils.setIntAttribute(name: "sb", value: startIndex, in: element)
        XMLUtils.setIntAttribute(name: "eb", value: endIndex, in: element)
        element.appendChild(XLText.textElement(text))
        return element
    }
}
