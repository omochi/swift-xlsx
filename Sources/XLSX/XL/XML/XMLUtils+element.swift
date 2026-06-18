import XLSXXML

extension XMLUtils {
    public static func ensureRootElement(name: String, in document: XMLDocument) -> XMLElement {
        if let element = document.element(name: name) {
            return element
        }

        let element = XMLElement(name: XMLName(name: name))
        document.appendChild(element)
        return element
    }

    public static func ensureChildElement(
        name: String,
        in parentElement: XMLElement,
        insertionIndex: (() -> Int?)? = nil
    ) -> XMLElement {
        if let element = parentElement.elements(name: name).first {
            return element
        }

        let element = XMLElement(name: XMLName(name: name))
        if let index = insertionIndex?() {
            parentElement.insertChild(element, at: index)
            return element
        }

        parentElement.appendChild(element)
        return element
    }
}
