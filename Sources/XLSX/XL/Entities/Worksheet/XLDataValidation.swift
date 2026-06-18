import MemberwiseInit

@MemberwiseInit(.public)
public struct XLDataValidation: Sendable & Hashable {
    public enum ErrorStyle: String, Sendable & Hashable {
        case stop
        case warning
        case information
    }

    public enum ImeMode: String, Sendable & Hashable {
        case noControl
        case off
        case on
        case disabled
        case hiragana
        case fullKatakana
        case halfKatakana
        case fullAlpha
        case halfAlpha
        case fullHangul
        case halfHangul
    }

    public enum Operator: String, Sendable & Hashable {
        case between
        case notBetween
        case equal
        case notEqual
        case lessThan
        case lessThanOrEqual
        case greaterThan
        case greaterThanOrEqual
    }

    public enum ValidationType: String, Sendable & Hashable {
        case none
        case whole
        case decimal
        case list
        case date
        case time
        case textLength
        case custom
    }

    public init(xmlElement: XMLElement) {
        self.sqref = xmlElement.attribute(name: "sqref").flatMap(XLCellRangeAddressList.init)
        self.validationType = xmlElement.attribute(name: "type").flatMap(ValidationType.init(rawValue:))
        self.validationOperator = xmlElement.attribute(name: "operator").flatMap(Operator.init(rawValue:))
        self.errorStyle = xmlElement.attribute(name: "errorStyle").flatMap(ErrorStyle.init(rawValue:))
        self.imeMode = xmlElement.attribute(name: "imeMode").flatMap(ImeMode.init(rawValue:))
        self.allowBlank = XMLUtils.boolAttribute(name: "allowBlank", in: xmlElement, defaultValue: nil)
        self.showDropDown = XMLUtils.boolAttribute(name: "showDropDown", in: xmlElement, defaultValue: nil)
        self.showInputMessage = XMLUtils.boolAttribute(name: "showInputMessage", in: xmlElement, defaultValue: nil)
        self.showErrorMessage = XMLUtils.boolAttribute(name: "showErrorMessage", in: xmlElement, defaultValue: nil)
        self.errorTitle = xmlElement.attribute(name: "errorTitle")
        self.error = xmlElement.attribute(name: "error")
        self.promptTitle = xmlElement.attribute(name: "promptTitle")
        self.prompt = xmlElement.attribute(name: "prompt")
        self.formula1 = Self.text(in: xmlElement.elements(name: "formula1").first)
        self.formula2 = Self.text(in: xmlElement.elements(name: "formula2").first)
        self.list = Self.text(in: Self.listElement(in: xmlElement))
    }

    public var sqref: XLCellRangeAddressList? = nil
    public var validationType: ValidationType? = nil
    public var validationOperator: Operator? = nil
    public var errorStyle: ErrorStyle? = nil
    public var imeMode: ImeMode? = nil
    public var allowBlank: Bool? = nil
    public var showDropDown: Bool? = nil
    public var showInputMessage: Bool? = nil
    public var showErrorMessage: Bool? = nil
    public var errorTitle: String? = nil
    public var error: String? = nil
    public var promptTitle: String? = nil
    public var prompt: String? = nil
    public var formula1: String? = nil
    public var formula2: String? = nil
    public var list: String? = nil

    func write(to xmlElement: XMLElement, x12acPrefix: String) {
        xmlElement.attributes = []
        xmlElement.children = children(x12acPrefix: x12acPrefix)
        xmlElement.setAttribute(name: "sqref", value: sqref?.description)
        xmlElement.setAttribute(name: "type", value: validationType?.rawValue)
        xmlElement.setAttribute(name: "operator", value: validationOperator?.rawValue)
        xmlElement.setAttribute(name: "errorStyle", value: errorStyle?.rawValue)
        xmlElement.setAttribute(name: "imeMode", value: imeMode?.rawValue)
        XMLUtils.setBoolAttribute(name: "allowBlank", value: allowBlank, in: xmlElement)
        XMLUtils.setBoolAttribute(name: "showDropDown", value: showDropDown, in: xmlElement)
        XMLUtils.setBoolAttribute(name: "showInputMessage", value: showInputMessage, in: xmlElement)
        XMLUtils.setBoolAttribute(name: "showErrorMessage", value: showErrorMessage, in: xmlElement)
        xmlElement.setAttribute(name: "errorTitle", value: errorTitle)
        xmlElement.setAttribute(name: "error", value: error)
        xmlElement.setAttribute(name: "promptTitle", value: promptTitle)
        xmlElement.setAttribute(name: "prompt", value: prompt)
    }

    private func children(x12acPrefix: String) -> [XMLNode] {
        var children: [XMLNode] = []
        if let formula1 {
            children.append(Self.element(name: XMLName(name: "formula1"), text: formula1))
        }
        if let formula2 {
            children.append(Self.element(name: XMLName(name: "formula2"), text: formula2))
        }
        if let list {
            children.append(Self.element(name: XMLName(prefix: x12acPrefix, name: "list"), text: list))
        }
        return children
    }

    private static func element(name: XMLName, text: String) -> XMLElement {
        XMLElement(
            name: name,
            children: [
                XMLText(text),
            ]
        )
    }

    private static func listElement(in xmlElement: XMLElement) -> XMLElement? {
        xmlElement.elements(name: "list").first { element in
            element.namespaceURI(for: element.name.prefix) == .spreadsheetX12
        }
    }

    private static func text(in element: XMLElement?) -> String? {
        guard let element else {
            return nil
        }

        let text = element.children.compactMap { ($0 as? XMLText)?.value }.joined()
        return text.isEmpty ? nil : text
    }
}
