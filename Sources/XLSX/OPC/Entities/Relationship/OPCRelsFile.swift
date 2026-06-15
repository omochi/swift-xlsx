import MemberwiseInit
import Foundation

@MemberwiseInit(.public)
public struct OPCRelsFile: Sendable, OPCFile {
    public init(data: Data) throws {
        let document = try XMLDocumentReader.parse(data)
        guard let root = document.element(name: "Relationships") else {
            throw OPCError.invalidRelationshipsFile
        }
        self.relationships = root.elements(name: "Relationship").compactMap { element in
            guard let id = element.attribute("Id"),
                  let type = element.attribute("Type"),
                  let target = element.attribute("Target")
            else {
                return nil
            }

            return OPCRelationship(id: id, type: type, target: target)
        }
    }

    public var relationships: [OPCRelationship] = []

    public static func path(for sourcePath: OPCFilePath) throws -> OPCFilePath {
        guard let fileName = sourcePath.components.last else {
            return try OPCFilePath(string: "/_rels/.rels")
        }

        let directoryComponents = sourcePath.components.dropLast()
        let components = Array(directoryComponents) + ["_rels", "\(fileName).rels"]
        return OPCFilePath(isAbsolute: sourcePath.isAbsolute, components: components)
    }

    @discardableResult
    public mutating func ensureRelationship(
        id: String,
        type: String,
        target: String
    ) -> OPCRelationship {
        if let index = relationships.firstIndex(where: { $0.id == id }) {
            relationships[index].type = type
            relationships[index].target = target
            return relationships[index]
        }

        let relationship = OPCRelationship(id: id, type: type, target: target)
        relationships.append(relationship)
        return relationship
    }

    @discardableResult
    public mutating func ensureRelationship(
        type: String,
        target: String
    ) -> OPCRelationship {
        if let relationship = relationships.first(where: { $0.type == type }) {
            return relationship
        }

        let relationship = OPCRelationship(
            id: nextRelationshipID(),
            type: type,
            target: target
        )
        relationships.append(relationship)
        return relationship
    }

    public func data() -> Data {
        xmlDocument.data()
    }

    private var xmlDocument: XMLDocument {
        let document = XMLDocument()
        let root = XMLElement(
            name: XMLName(name: "Relationships"),
            namespaces: XMLNamespaceTable().declared(
                uri: XMLNamespaceURI(OPCXMLNamespaces.relationships)
            )
        )

        for relationship in relationships {
            root.appendChild(XMLElement(
                name: XMLName(name: "Relationship"),
                attributes: [
                    XMLAttribute(
                        name: XMLName(name: "Id"),
                        value: relationship.id
                    ),
                    XMLAttribute(
                        name: XMLName(name: "Type"),
                        value: relationship.type
                    ),
                    XMLAttribute(
                        name: XMLName(name: "Target"),
                        value: relationship.target
                    ),
                ]
            ))
        }

        document.appendChild(root)
        return document
    }

    private func nextRelationshipID() -> String {
        let maxID = relationships.compactMap { relationship -> Int? in
            guard relationship.id.hasPrefix("rId") else {
                return nil
            }
            return Int(relationship.id.dropFirst(3))
        }.max() ?? 0

        return "rId\(maxID + 1)"
    }
}
