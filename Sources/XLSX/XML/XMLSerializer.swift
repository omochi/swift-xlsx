struct XMLSerializer {
    init(pretty: Bool = false) {
        self.pretty = pretty
    }

    var pretty: Bool

    func serialize(document: XMLDocument) -> String {
        var output = #"<?xml version="1.0" encoding="UTF-8" standalone="yes"?>"#
        for child in document.children {
            if pretty, isDocumentFormattingText(child) {
                continue
            }
            if pretty, child is XMLElement {
                output += "\n"
            }
            output += serialize(node: child, depth: 0)
        }
        if pretty {
            output += "\n"
        }
        return output
    }

    private func isDocumentFormattingText(_ node: XMLNode) -> Bool {
        guard let text = node as? XMLText else {
            return false
        }
        return text.value.allSatisfy(\.isWhitespace)
    }

    func serialize(element: XMLElement) -> String {
        var output = serialize(element: element, depth: 0)
        if pretty {
            output += "\n"
        }
        return output
    }

    private func serialize(element: XMLElement, depth: Int) -> String {
        if pretty {
            return serializePretty(element: element, depth: depth)
        }
        return serializeCompact(element: element)
    }

    private func serializeCompact(element: XMLElement) -> String {
        if element.children.isEmpty {
            return serializeCompactStartTag(element: element, closing: "/>")
        }

        var output = serializeCompactStartTag(element: element, closing: ">")
        output += element.children.map(serializeCompact(node:)).joined()
        output += "</\(element.name.qualifiedName)>"
        return output
    }

    private func serializePretty(element: XMLElement, depth: Int) -> String {
        if element.children.isEmpty {
            return serializePrettyStartTag(element: element, depth: depth, closing: "/>")
        }

        var output = serializePrettyStartTag(element: element, depth: depth, closing: ">")
        if element.children.contains(where: { $0 is XMLText }) {
            output += element.children.map(serializeCompact(node:)).joined()
            output += "</\(element.name.qualifiedName)>"
            return output
        }

        for child in element.children {
            output += "\n"
            output += serialize(node: child, depth: depth + 1)
        }
        output += "\n"
        let indent = indentation(depth: depth)
        output += "\(indent)</\(element.name.qualifiedName)>"
        return output
    }

    private func serialize(node: XMLNode, depth: Int) -> String {
        switch node {
        case let element as XMLElement:
            return serialize(element: element, depth: depth)
        case let text as XMLText:
            return escapeText(text.value)
        default:
            return node.children.map { serialize(node: $0, depth: depth) }.joined()
        }
    }

    private func serializeCompact(node: XMLNode) -> String {
        switch node {
        case let element as XMLElement:
            return serializeCompact(element: element)
        case let text as XMLText:
            return escapeText(text.value)
        default:
            return node.children.map(serializeCompact(node:)).joined()
        }
    }

    private func serializeCompactStartTag(element: XMLElement, closing: String) -> String {
        "<\(element.name.qualifiedName)\(serializeCompactAttributes(element: element))\(closing)"
    }

    private func serializePrettyStartTag(element: XMLElement, depth: Int, closing: String) -> String {
        let indent = indentation(depth: depth)
        let attributes = serializeAttributeItems(element: element)
        let inline = "\(indent)<\(element.name.qualifiedName)\(serializeCompactAttributes(attributes: attributes))\(closing)"

        guard !attributes.isEmpty, inline.count > 100 else {
            return inline
        }

        let attributeIndent = indentation(depth: depth + 1)
        var output = "\(indent)<\(element.name.qualifiedName)"
        for attribute in attributes {
            output += "\n"
            output += "\(attributeIndent)\(attribute)"
        }
        output += closing
        return output
    }

    private func serializeCompactAttributes(element: XMLElement) -> String {
        serializeCompactAttributes(attributes: serializeAttributeItems(element: element))
    }

    private func serializeCompactAttributes(attributes: [String]) -> String {
        attributes.map { " \($0)" }.joined()
    }

    private func serializeAttributeItems(element: XMLElement) -> [String] {
        var attributes: [String] = []
        for declaration in element.namespaces.declarations {
            attributes.append("\(namespaceDeclarationName(for: declaration.prefix))=\"\(escapeAttribute(declaration.uri.string))\"")
        }
        for attribute in element.attributes {
            attributes.append("\(attribute.name.qualifiedName)=\"\(escapeAttribute(attribute.value))\"")
        }
        return attributes
    }

    private func indentation(depth: Int) -> String {
        String(repeating: " ", count: depth * 4)
    }

    private func namespaceDeclarationName(for prefix: String?) -> String {
        guard let prefix else {
            return "xmlns"
        }
        return "xmlns:\(prefix)"
    }

    private func escapeText(_ string: String) -> String {
        string
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
    }

    private func escapeAttribute(_ string: String) -> String {
        escapeText(string)
            .replacingOccurrences(of: "\"", with: "&quot;")
    }
}
