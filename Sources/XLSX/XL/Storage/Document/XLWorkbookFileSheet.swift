import MemberwiseInit

@MemberwiseInit(.public)
public struct XLWorkbookFileSheet: Sendable & Hashable {
    public init?(element: XMLElement) {
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

    public func write(to element: XMLElement) throws {
        element.setAttribute(name: "name", value: name)
        element.setAttribute(name: "sheetId", value: String(sheetID))
        try element.setAttribute(
            namespaceURI: .officeRelationships,
            name: "id",
            value: relationshipID
        )
    }
}
