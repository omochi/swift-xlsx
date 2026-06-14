import MemberwiseInit
import Foundation

@MemberwiseInit(.public)
public struct OPCRelsFile: Sendable {
    public init(data: Data?) throws {
        guard let data else {
            self.relationships = []
            return
        }

        let document = try XMLDocumentReader.parse(data)
        let root = XMLDocument.firstElement(named: "Relationships", in: document) ?? document
        self.relationships = XMLDocument.children(of: root, in: document).compactMap { child in
            guard document.kind(of: child) == .element,
                  XMLDocument.name(of: child, in: document) == "Relationship",
                  let id = XMLDocument.attribute("Id", of: child, in: document),
                  let type = XMLDocument.attribute("Type", of: child, in: document),
                  let target = XMLDocument.attribute("Target", of: child, in: document)
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
        return try OPCFilePath(string: components.joined(separator: "/"))
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
        preferredTarget: String
    ) -> OPCRelationship {
        if let relationship = relationships.first(where: { $0.type == type }) {
            return relationship
        }

        let relationship = OPCRelationship(
            id: nextRelationshipID(),
            type: type,
            target: preferredTarget
        )
        relationships.append(relationship)
        return relationship
    }

    public func data() -> Data {
        Data(xmlString.utf8)
    }

    private var xmlString: String {
        var lines = [
            #"<?xml version="1.0" encoding="UTF-8" standalone="yes"?>"#,
            #"<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">"#,
        ]

        for relationship in relationships {
            lines.append(#"  <Relationship Id="\#(escape(relationship.id))" Type="\#(escape(relationship.type))" Target="\#(escape(relationship.target))"/>"#)
        }

        lines.append("</Relationships>")
        return lines.joined(separator: "\n")
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

    private func escape(_ string: String) -> String {
        string
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
    }
}
