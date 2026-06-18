public enum XLFormula {
    public enum Kind: String, Sendable, Hashable {
        case normal
        case shared
        case array
        case dataTable
    }
}
