import XLSXXML

public enum XLSheetState: String, Sendable & Hashable {
    case visible
    case hidden
    case veryHidden

    public init(element: XMLElement) {
        self = element.attribute(name: "state").flatMap(Self.init(rawValue:)) ?? .visible
    }

    public func write(to element: XMLElement) {
        element.setAttribute(name: "state", value: self == .visible ? nil : rawValue)
    }
}
