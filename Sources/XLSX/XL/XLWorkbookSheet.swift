import MemberwiseInit

@MemberwiseInit(.public)
public struct XLWorkbookSheet: Sendable & Hashable {
    init?(element: XMLElement) {
        guard let name = element.attribute(name: "name"),
              let sheetIDText = element.attribute(name: "sheetId"),
              let sheetID = Int(sheetIDText),
              let relationshipID = element.attribute(
                name: "id",
                namespaceURI: .officeRelationships
              )
        else {
            return nil
        }

        self.name = name
        self.sheetID = sheetID
        self.relationshipID = relationshipID
    }

    public var name: String
    public var sheetID: Int
    public var relationshipID: String

    func ensureElement(in sheetsElement: XMLElement) throws {
        let element = sheetElement(in: sheetsElement)

        try element.setAttribute(name: "name", value: name)
        try element.setAttribute(name: "sheetId", value: String(sheetID))
        try element.setAttribute(
            name: "id",
            namespaceURI: .officeRelationships,
            value: relationshipID
        )
    }

    private func sheetElement(in sheetsElement: XMLElement) -> XMLElement {
        if let element = sheetsElement.elements(name: "sheet").first(where: { element in
            XLWorkbookSheet(element: element)?.sheetID == sheetID
        }) {
            return element
        }

        let element = XMLElement(name: XMLName(name: "sheet"))
        sheetsElement.appendChild(element)
        return element
    }
}
