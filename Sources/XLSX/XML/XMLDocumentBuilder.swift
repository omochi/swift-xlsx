import SAXParser
import XMLCore

struct XMLDocumentBuilder: Handler {
    init() {
        self.stack = [document]
    }

    var document = XMLDocument()
    var stack: [XMLNode] = []
    private var pendingNamespaces = XMLNamespaceTable()

    mutating func start(mapping prefix: Span<XML.Byte>?, uri: Span<XML.Byte>) {
        let namespacePrefix: String?
        if let prefix {
            namespacePrefix = Self.string(from: prefix)
        } else {
            namespacePrefix = nil
        }

        pendingNamespaces.declare(
            prefix: namespacePrefix,
            uri: XMLNamespaceURI(Self.string(from: uri))
        )
    }

    mutating func start(
        element name: XML.QualifiedNameView,
        namespace uri: Span<XML.Byte>?,
        attributes: XML.ResolvedAttributes
    ) {
        let elementNamespaces = pendingNamespaces
        pendingNamespaces = XMLNamespaceTable()
        var elementAttributes: [XMLAttribute] = []

        for index in attributes.indices {
            elementAttributes.append(XMLAttribute(
                name: xmlName(qualifiedName: Self.string(from: attributes.name(at: index).bytes)),
                value: Self.string(from: attributes.value(at: index))
            ))
        }

        let element = XMLElement(
            name: xmlName(qualifiedName: Self.string(from: name.bytes)),
            namespaces: elementNamespaces,
            attributes: elementAttributes
        )
        stack.last?.appendChild(element)
        stack.append(element)
    }

    mutating func end(element name: XML.QualifiedNameView, namespace uri: Span<XML.Byte>?) {
        _ = stack.popLast()
    }

    mutating func characters(_ data: Span<XML.Byte>) {
        stack.last?.appendChild(XMLText(Self.string(from: data)))
    }

    mutating func character(data: Span<XML.Byte>) {
        stack.last?.appendChild(XMLText(Self.string(from: data)))
    }

    private mutating func xmlName(qualifiedName: String) -> XMLName {
        if let colonIndex = qualifiedName.firstIndex(of: ":") {
            return XMLName(
                prefix: String(qualifiedName[..<colonIndex]),
                name: String(qualifiedName[qualifiedName.index(after: colonIndex)...])
            )
        }
        return XMLName(name: qualifiedName)
    }

    private static func string(from bytes: Span<XML.Byte>) -> String {
        bytes.withUnsafeBufferPointer { String(decoding: $0, as: UTF8.self) }
    }
}
