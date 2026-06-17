public struct XLCellStyle: Hashable {
    public init(
        name: String? = nil,
        format: XLCellStyleFormatRef? = nil,
        builtinID: Int? = nil,
        customBuiltin: Bool? = nil,
        hidden: Bool? = nil,
        outlineLevel: Int? = nil,
        uniqueIdentifier: String? = nil
    ) {
        self.name = name
        self.format = format
        self.builtinID = builtinID
        self.customBuiltin = customBuiltin
        self.hidden = hidden
        self.outlineLevel = outlineLevel
        self.uniqueIdentifier = uniqueIdentifier
    }

    public init(
        element: XMLElement,
        cellStyleFormats: XLCellStyleFormatRefsStorage
    ) {
        let styleFormatID = XMLUtils.intAttribute(name: "xfId", in: element)
        self.init(
            name: element.attribute(name: "name"),
            format: styleFormatID.flatMap { cellStyleFormats.record(at: $0) },
            builtinID: XMLUtils.intAttribute(name: "builtinId", in: element),
            customBuiltin: XMLUtils.boolAttribute(name: "customBuiltin", in: element, defaultValue: nil),
            hidden: XMLUtils.boolAttribute(name: "hidden", in: element, defaultValue: nil),
            outlineLevel: XMLUtils.intAttribute(name: "iLevel", in: element),
            uniqueIdentifier: element.attribute(name: "uid", namespaceURI: .spreadsheetRevision)
        )
    }

    public var name: String?
    public var format: XLCellStyleFormatRef?
    public var builtinID: Int?
    public var customBuiltin: Bool?
    public var hidden: Bool?
    public var outlineLevel: Int?
    public var uniqueIdentifier: String?

    public static func == (lhs: XLCellStyle, rhs: XLCellStyle) -> Bool {
        lhs.name == rhs.name &&
            lhs.format == rhs.format &&
            lhs.builtinID == rhs.builtinID &&
            lhs.customBuiltin == rhs.customBuiltin &&
            lhs.hidden == rhs.hidden &&
            lhs.outlineLevel == rhs.outlineLevel &&
            lhs.uniqueIdentifier == rhs.uniqueIdentifier
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(name)
        hasher.combine(format)
        hasher.combine(builtinID)
        hasher.combine(customBuiltin)
        hasher.combine(hidden)
        hasher.combine(outlineLevel)
        hasher.combine(uniqueIdentifier)
    }

    public func xmlElement(
        cellStyleFormats: XLCellStyleFormatRefsStorage,
        revisionNamespacePrefix: String?
    ) -> XMLElement {
        let element = XMLElement(name: XMLName(name: "cellStyle"))
        XMLUtils.setStringAttribute(name: "name", value: name, in: element)
        XMLUtils.setIntAttribute(name: "xfId", value: styleFormatID(in: cellStyleFormats), in: element)
        XMLUtils.setIntAttribute(name: "builtinId", value: builtinID, in: element)
        XMLUtils.setBoolAttribute(name: "customBuiltin", value: customBuiltin, in: element)
        XMLUtils.setBoolAttribute(name: "hidden", value: hidden, in: element)
        XMLUtils.setIntAttribute(name: "iLevel", value: outlineLevel, in: element)
        if let uniqueIdentifier,
           let revisionNamespacePrefix
        {
            element.attributes.append(XMLAttribute(
                name: XMLName(prefix: revisionNamespacePrefix, name: "uid"),
                value: uniqueIdentifier
            ))
        }
        return element
    }

    private func styleFormatID(in cellStyleFormats: XLCellStyleFormatRefsStorage) -> Int? {
        guard let format else {
            return nil
        }

        return cellStyleFormats.index(for: format)
    }
}
