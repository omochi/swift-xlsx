public enum XLNumberFormat: Sendable & Hashable {
    case builtin(id: Int)
    case format(String)

    public static let customFormatFirstID = 164
}
