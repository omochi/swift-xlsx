import MemberwiseInit
import XLSXXML

@MemberwiseInit(.public)
public struct XLDataValidations: Sendable & Hashable {
    public init(xmlElement: XMLElement) {
        self.validations = xmlElement.elements(name: "dataValidation").map { element in
            XLDataValidation(xmlElement: element)
        }
        self.disablePrompts = XMLUtils.boolAttribute(name: "disablePrompts", in: xmlElement, defaultValue: nil)
        self.xWindow = XMLUtils.intAttribute(name: "xWindow", in: xmlElement)
        self.yWindow = XMLUtils.intAttribute(name: "yWindow", in: xmlElement)
    }

    public var validations: [XLDataValidation] = []
    public var disablePrompts: Bool? = nil
    public var xWindow: Int? = nil
    public var yWindow: Int? = nil

    public var isEmpty: Bool {
        validations.isEmpty
    }

    func write(to xmlElement: XMLElement) {
        xmlElement.attributes = []
        XMLUtils.setIntAttribute(name: "count", value: validations.count, in: xmlElement)
        XMLUtils.setBoolAttribute(name: "disablePrompts", value: disablePrompts, in: xmlElement)
        XMLUtils.setIntAttribute(name: "xWindow", value: xWindow, in: xmlElement)
        XMLUtils.setIntAttribute(name: "yWindow", value: yWindow, in: xmlElement)
        xmlElement.children = validations.map { validation in
            let element = XMLElement(name: XMLName(name: "dataValidation"))
            validation.write(to: element)
            return element
        }
    }
}
