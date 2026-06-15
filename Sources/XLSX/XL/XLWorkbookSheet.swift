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

    func write(to element: XMLElement) throws {
        try element.setAttribute(name: "name", value: name)
        try element.setAttribute(name: "sheetId", value: String(sheetID))
        try element.setAttribute(
            name: "id",
            namespaceURI: .officeRelationships,
            value: relationshipID
        )
    }
}
