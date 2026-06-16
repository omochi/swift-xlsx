import MemberwiseInit
import Foundation

@MemberwiseInit(.public)
public struct OPCRelsFile: Sendable, XMLDocumentConvertible {
    public init(xmlDocument: XMLDocument) throws {
        guard let root = xmlDocument.element(name: "Relationships") else {
            throw OPCError.invalidRelationshipsFile
        }
        self.relationships = root.elements(name: "Relationship").compactMap { element in
            guard let id = element.attribute(name: "Id"),
                  let type = element.attribute(name: "Type"),
                  let target = element.attribute(name: "Target")
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
        target: String?
    ) -> OPCRelationship? {
        guard let target else {
            relationships.removeAll { $0.type == type }
            return nil
        }

        if let index = relationships.firstIndex(where: { $0.type == type }) {
            relationships[index].target = target
            return relationships[index]
        }

        let relationship = OPCRelationship(
            id: nextRelationshipID(),
            type: type,
            target: target
        )
        relationships.append(relationship)
        return relationship
    }

    @discardableResult
    public mutating func removeRelationship(id: String) -> OPCRelationship? {
        guard let index = relationships.firstIndex(where: { $0.id == id }) else {
            return nil
        }
        return relationships.remove(at: index)
    }

    public func xmlDocument() -> XMLDocument {
        let document = XMLDocument()
        let root = XMLElement(
            name: XMLName(name: "Relationships"),
            namespaces: XMLNamespaceTable().declared(
                uri: .relationships
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
