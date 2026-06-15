public struct XLWorksheet: OPCXMLFile {
    public init() {
        self.original = nil
    }

    public init(xmlDocument: XMLDocument) throws {
        self.original = xmlDocument
    }

    public var original: XMLDocument?

    public func xmlDocument() -> XMLDocument {
        guard let original else {
            let document = XMLDocument()
            let worksheetElement = worksheetElement(in: document)
            worksheetElement.ensureNamespace(uri: .spreadsheet)
            return document
        }

        let document = original.clone()
        return document
    }

    private func worksheetElement(in document: XMLDocument) -> XMLElement {
        if let element = document.element(name: "worksheet") {
            return element
        }

        let element = XMLElement(name: XMLName(name: "worksheet"))
        document.appendChild(element)
        return element
    }
}
