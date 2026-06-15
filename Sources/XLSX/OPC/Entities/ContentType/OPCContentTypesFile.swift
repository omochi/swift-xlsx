import MemberwiseInit
import Foundation

@MemberwiseInit(.public)
public struct OPCContentTypesFile {
    public init(data: Data?) throws {
        guard let data else {
            self.init()
            return
        }

        let document = try XMLDocumentReader.parse(data)
        guard let root = document.element(name: "Types") else {
            throw OPCError.invalidContentTypesFile
        }
        var defaults: [String: String] = [:]
        var overrides: [OPCFilePath: String] = [:]

        for element in root.elements(name: "Default") {
            guard let extensionName = element.attribute("Extension"),
                  let contentType = element.attribute("ContentType")
            else {
                continue
            }
            defaults[extensionName] = contentType
        }

        for element in root.elements(name: "Override") {
            guard let partName = element.attribute("PartName"),
                  let contentType = element.attribute("ContentType")
            else {
                continue
            }
            overrides[try OPCFilePath(string: partName)] = contentType
        }

        self.init(defaults: defaults, overrides: overrides)
    }

    public var defaults: [String: String] = [:]
    public var overrides: [OPCFilePath: String] = [:]

    public mutating func ensureDefault(extension extensionName: String, contentType: String) {
        defaults[extensionName] = contentType
    }

    public mutating func ensureOverride(partName: OPCFilePath, contentType: String) {
        overrides[partName] = contentType
    }

    public func data() -> Data {
        xmlDocument.data()
    }

    private var xmlDocument: XMLDocument {
        let document = XMLDocument()
        let root = XMLElement(
            name: XMLName(name: "Types"),
            namespaces: XMLNamespaceTable().declared(
                uri: document.internNamespaceURI(OPCXMLNamespaces.contentTypes)
            )
        )

        for extensionName in defaults.keys.sorted() {
            guard let contentType = defaults[extensionName] else {
                continue
            }
            root.appendChild(XMLElement(
                name: XMLName(name: "Default"),
                attributes: [
                    XMLAttribute(
                        name: XMLName(name: "Extension"),
                        value: extensionName
                    ),
                    XMLAttribute(
                        name: XMLName(name: "ContentType"),
                        value: contentType
                    ),
                ]
            ))
        }

        for partName in overrides.keys.sorted(by: { $0.description < $1.description }) {
            guard let contentType = overrides[partName] else {
                continue
            }
            root.appendChild(XMLElement(
                name: XMLName(name: "Override"),
                attributes: [
                    XMLAttribute(
                        name: XMLName(name: "PartName"),
                        value: partName.description
                    ),
                    XMLAttribute(
                        name: XMLName(name: "ContentType"),
                        value: contentType
                    ),
                ]
            ))
        }

        document.appendChild(root)
        return document
    }
}
