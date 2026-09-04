import XLSXXML

public struct XLText: Sendable & Hashable & CustomStringConvertible {
    public enum Content: Sendable & Hashable {
        case plain(String)
        case rich([XLTextRun])
    }

    public init(
        content: Content,
        phoneticRuns: [XLPhoneticRun] = [],
        phoneticProperties: XLPhoneticProperties? = nil
    ) {
        self.content = content
        self.phoneticRuns = phoneticRuns
        self.phoneticProperties = phoneticProperties
    }

    public init(_ text: String) {
        self.init(content: .plain(text))
    }

    public init(element: XMLElement) {
        var plainText: String?
        var richTextRuns: [XLTextRun] = []
        var phoneticRuns: [XLPhoneticRun] = []
        var phoneticProperties: XLPhoneticProperties?

        for child in element.children {
            guard let childElement = child as? XMLElement else { continue }

            switch childElement.name.name {
            case "t": plainText = Self.textContent(in: childElement)
            case "r": richTextRuns.append(XLTextRun(element: childElement))
            case "rPh": phoneticRuns.append(XLPhoneticRun(element: childElement))
            case "phoneticPr": phoneticProperties = XLPhoneticProperties(element: childElement)
            default: continue
            }
        }

        self.content = plainText.map(Content.plain) ?? .rich(richTextRuns)
        self.phoneticRuns = phoneticRuns
        self.phoneticProperties = phoneticProperties
    }

    public var content: Content
    public var phoneticRuns: [XLPhoneticRun]
    public var phoneticProperties: XLPhoneticProperties?

    public var string: String {
        switch content {
        case .plain(let text): return text
        case .rich(let runs): return runs.map(\.text).joined()
        }
    }

    public var description: String { string }

    public func xmlElement(name: String) throws -> XMLElement {
        let element = XMLElement(name: XMLName(name: name))

        switch content {
        case .plain(let text):
            element.appendChild(Self.textElement(text))
        case .rich(let runs):
            for run in runs {
                element.appendChild(try run.xmlElement())
            }
        }

        for run in phoneticRuns {
            element.appendChild(run.xmlElement())
        }
        if let phoneticProperties {
            element.appendChild(phoneticProperties.xmlElement())
        }

        return element
    }

    static func textElement(_ text: String) -> XMLElement {
        let element = XMLElement(name: XMLName(name: "t"))
        if text != text.trimmingCharacters(in: .whitespacesAndNewlines) {
            element.setAttribute(uncheckedPrefix: "xml", name: "space", value: "preserve")
        }
        element.appendChild(XMLText(text))
        return element
    }

    static func textContent(in node: XMLNode) -> String {
        if let text = node as? XMLText {
            return text.value
        }
        return node.children.map { textContent(in: $0) }.joined()
    }
}
