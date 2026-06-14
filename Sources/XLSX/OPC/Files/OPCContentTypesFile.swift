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
        let root = XMLDocument.firstElement(named: "Types", in: document) ?? document
        var defaults: [String: String] = [:]
        var overrides: [OPCFilePath: String] = [:]

        for child in XMLDocument.children(of: root, in: document) {
            guard let element = child as? XMLElement else {
                continue
            }

            switch element.name.rawName {
            case "Default":
                guard let extensionName = XMLDocument.attribute("Extension", of: element, in: document),
                      let contentType = XMLDocument.attribute("ContentType", of: element, in: document)
                else {
                    continue
                }
                defaults[extensionName] = contentType

            case "Override":
                guard let partName = XMLDocument.attribute("PartName", of: element, in: document),
                      let contentType = XMLDocument.attribute("ContentType", of: element, in: document)
                else {
                    continue
                }
                overrides[try OPCFilePath(string: partName)] = contentType

            default:
                continue
            }
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
        let root = XMLElement(
            name: XMLName(rawName: "Types", namespaceID: nil),
            attributes: [
                XMLAttribute(
                    name: XMLName(rawName: "xmlns", namespaceID: nil),
                    value: "http://schemas.openxmlformats.org/package/2006/content-types"
                ),
            ]
        )

        for extensionName in defaults.keys.sorted() {
            guard let contentType = defaults[extensionName] else {
                continue
            }
            root.appendChild(XMLElement(
                name: XMLName(rawName: "Default", namespaceID: nil),
                attributes: [
                    XMLAttribute(
                        name: XMLName(rawName: "Extension", namespaceID: nil),
                        value: extensionName
                    ),
                    XMLAttribute(
                        name: XMLName(rawName: "ContentType", namespaceID: nil),
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
                name: XMLName(rawName: "Override", namespaceID: nil),
                attributes: [
                    XMLAttribute(
                        name: XMLName(rawName: "PartName", namespaceID: nil),
                        value: partName.description
                    ),
                    XMLAttribute(
                        name: XMLName(rawName: "ContentType", namespaceID: nil),
                        value: contentType
                    ),
                ]
            ))
        }

        return XMLDocument(children: [root])
    }
}
