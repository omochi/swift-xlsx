struct XLSharedStringCollector {
    var usedTexts: Set<String> = []
    var orderedTexts: [String] = []
    var usedOpaqueIndices: Set<Int> = []

    mutating func collect(_ value: XLCellValue) {
        switch value {
        case let .string(text):
            if usedTexts.insert(text).inserted {
                orderedTexts.append(text)
            }
        case let .opaqueSharedString(index):
            usedOpaqueIndices.insert(index)
        }
    }
}
