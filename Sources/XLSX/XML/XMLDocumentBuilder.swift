import SAXParser
import XMLCore

public struct XMLDocumentBuilder: Handler {
    public init() {
        self.stack = [document]
    }

    public var document = XMLDocument()
    public var stack: [XMLNode] = []
    private var pendingNamespaceAttributes: [XMLAttribute] = []

    public mutating func start(mapping prefix: Span<XML.Byte>?, uri: Span<XML.Byte>) {
        let rawName: String
        if let prefix {
            rawName = "xmlns:\(Self.string(from: prefix))"
        } else {
            rawName = "xmlns"
        }

        pendingNamespaceAttributes.append(XMLAttribute(
            name: XMLName(rawName: rawName, namespaceID: nil),
            value: Self.string(from: uri)
        ))
    }

    public mutating func start(
        element name: XML.QualifiedNameView,
        namespace uri: Span<XML.Byte>?,
        attributes: XML.ResolvedAttributes
    ) {
        var elementAttributes = pendingNamespaceAttributes
        pendingNamespaceAttributes.removeAll(keepingCapacity: true)

        for index in attributes.indices {
            elementAttributes.append(XMLAttribute(
                name: xmlName(rawName: Self.string(from: attributes.name(at: index).bytes),
                              namespaceURI: Self.optionalString(from: attributes.namespace(at: index))),
                value: Self.string(from: attributes.value(at: index))
            ))
        }

        let element = XMLElement(
            name: xmlName(rawName: Self.string(from: name.bytes), namespaceURI: Self.optionalString(from: uri)),
            attributes: elementAttributes
        )
        stack.last?.appendChild(element)
        stack.append(element)
    }

    public mutating func end(element name: XML.QualifiedNameView, namespace uri: Span<XML.Byte>?) {
        _ = stack.popLast()
    }

    public mutating func characters(_ data: Span<XML.Byte>) {
        stack.last?.appendChild(XMLText(Self.string(from: data)))
    }

    public mutating func character(data: Span<XML.Byte>) {
        stack.last?.appendChild(XMLText(Self.string(from: data)))
    }

    private mutating func xmlName(rawName: String, namespaceURI: String?) -> XMLName {
        XMLName(rawName: rawName, namespaceID: document.namespaces.intern(namespaceURI))
    }

    private static func optionalString(from bytes: Span<XML.Byte>?) -> String? {
        guard let bytes else {
            return nil
        }
        return string(from: bytes)
    }

    private static func string(from bytes: Span<XML.Byte>) -> String {
        bytes.withUnsafeBufferPointer { String(decoding: $0, as: UTF8.self) }
    }
}
