enum XMLUtils {
    static func patchChildren<Record>(
        in parentElement: XMLElement,
        replacingElementsNamed childName: String,
        with records: [Record],
        makeElement: (Record) throws -> XMLElement
    ) rethrows -> [XMLNode] {
        var children: [XMLNode] = []
        var recordIndex = 0
        for child in parentElement.children {
            guard let element = child as? XMLElement,
                  element.name.name == childName
            else {
                children.append(child)
                continue
            }

            if records.indices.contains(recordIndex) {
                children.append(try makeElement(records[recordIndex]))
                recordIndex += 1
            }
        }

        children += try records.dropFirst(recordIndex).map { try makeElement($0) as XMLNode }
        return children
    }
}
