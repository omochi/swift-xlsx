import OrderedCollections

public enum XLNumberFormat: Sendable & Hashable {
    case builtin(id: Int)
    case format(String)

    public static let customFormatFirstID = 164

    public static func customNumberFormatID(
        for format: String,
        in numberFormats: OrderedSet<String>
    ) -> Int? {
        guard let index = numberFormats.firstIndex(of: format) else {
            return nil
        }

        return customFormatFirstID + index
    }

    public static func customNumberFormat(
        for id: Int,
        in numberFormats: OrderedSet<String>
    ) -> String? {
        let index = id - customFormatFirstID
        guard numberFormats.indices.contains(index) else {
            return nil
        }

        return numberFormats[index]
    }
}
