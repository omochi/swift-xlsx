struct XMLSerializer {
    init() {}

    func serialize(document: XMLDocument) -> String {
        var output = #"<?xml version="1.0" encoding="UTF-8" standalone="yes"?>"#
        for child in document.children {
            output += serialize(node: child)
        }
        return output
    }

    func serialize(element: XMLElement) -> String {
        var output = "<\(element.name.qualifiedName)"
        for declaration in element.namespaces.declarations {
            output += " \(namespaceDeclarationName(for: declaration.prefix))=\"\(escapeAttribute(declaration.uri.string))\""
        }
        for attribute in element.attributes {
            output += " \(attribute.name.qualifiedName)=\"\(escapeAttribute(attribute.value))\""
        }

        if element.children.isEmpty {
            output += "/>"
            return output
        }

        output += ">"
        output += element.children.map(serialize(node:)).joined()
        output += "</\(element.name.qualifiedName)>"
        return output
    }

    private func serialize(node: XMLNode) -> String {
        switch node {
        case let element as XMLElement:
            return serialize(element: element)
        case let text as XMLText:
            return escapeText(text.value)
        default:
            return node.children.map(serialize(node:)).joined()
        }
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
