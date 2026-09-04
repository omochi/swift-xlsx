import MemberwiseInit
import XLSXXML

@MemberwiseInit(.public)
public struct XLPhoneticProperties: Sendable & Hashable {
    public init(element: XMLElement) {
        self.fontID = XMLUtils.intAttribute(name: "fontId", in: element)
        self.type = element.attribute(name: "type")
        self.alignment = element.attribute(name: "alignment")
    }

    public var fontID: Int? = nil
    public var type: String? = nil
    public var alignment: String? = nil

    public func xmlElement() -> XMLElement {
        let element = XMLElement(name: XMLName(name: "phoneticPr"))
        XMLUtils.setIntAttribute(name: "fontId", value: fontID, in: element)
        XMLUtils.setStringAttribute(name: "type", value: type, in: element)
        XMLUtils.setStringAttribute(name: "alignment", value: alignment, in: element)
        return element
    }
}
