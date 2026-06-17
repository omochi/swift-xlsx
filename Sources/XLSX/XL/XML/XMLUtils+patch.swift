extension XMLUtils {
    public static func patchChildren<Records: Collection>(
        parentElement: XMLElement,
        replacingElementName: String,
        records: Records,
        makeElement: (Records.Element) throws -> XMLElement
    ) rethrows -> [XMLNode] {
        var children: [XMLNode] = []
        var recordIndex = records.startIndex
        for child in parentElement.children {
            guard let element = child as? XMLElement,
                  element.name.name == replacingElementName
            else {
                children.append(child)
                continue
            }

            if recordIndex != records.endIndex {
                children.append(try makeElement(records[recordIndex]))
                records.formIndex(after: &recordIndex)
            }
        }

        children += try records[recordIndex...].map { try makeElement($0) as XMLNode }
        return children
    }
}
