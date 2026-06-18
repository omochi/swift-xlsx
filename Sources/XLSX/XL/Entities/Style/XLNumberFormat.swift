import OrderedCollections

public enum XLNumberFormat: Sendable & Hashable {
    case builtin(id: Int)
    case format(String)

    public static var general: Self { .builtin(id: 0) }
    public static var integer: Self { .builtin(id: 1) }
    public static var decimal2: Self { .builtin(id: 2) }
    public static var thousandsInteger: Self { .builtin(id: 3) }
    public static var thousandsDecimal2: Self { .builtin(id: 4) }
    public static var percent: Self { .builtin(id: 9) }
    public static var percentDecimal2: Self { .builtin(id: 10) }
    public static var date: Self { .builtin(id: 14) }
    public static var time: Self { .builtin(id: 20) }
    public static var timeWithSeconds: Self { .builtin(id: 21) }
    public static var dateTime: Self { .builtin(id: 22) }
    public static var elapsedTime: Self { .builtin(id: 46) }
    public static var text: Self { .builtin(id: 49) }

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
