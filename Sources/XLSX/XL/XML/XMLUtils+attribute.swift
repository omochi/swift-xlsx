extension XMLUtils {
    static func boolValue(string: String) -> Bool? {
        if let number = Int(string) {
            return number != 0
        }

        switch string.lowercased() {
        case "true", "yes":
            return true
        case "false", "no":
            return false
        default:
            return nil
        }
    }

    static func intAttribute(name: String, in element: XMLElement) -> Int? {
        guard let value = element.attribute(name: name) else {
            return nil
        }
        return Int(value)
    }

    static func doubleAttribute(name: String, in element: XMLElement) -> Double? {
        guard let value = element.attribute(name: name) else {
            return nil
        }
        return Double(value)
    }

    static func boolAttribute(
        name: String,
        in element: XMLElement,
        defaultValue: Bool = false
    ) -> Bool {
        guard let value = element.attribute(name: name) else {
            return defaultValue
        }
        return boolValue(string: value) ?? false
    }

    static func setAttribute(name: String, value: Int?, in element: XMLElement) {
        guard let value else {
            return
        }
        element.setAttribute(name: name, value: String(value))
    }

    static func setAttribute(name: String, value: Double?, in element: XMLElement) {
        guard let value else {
            return
        }
        element.setAttribute(name: name, value: String(value))
    }

    static func setAttribute(name: String, value: String?, in element: XMLElement) {
        guard let value else {
            return
        }
        element.setAttribute(name: name, value: value)
    }

    static func setAttribute(name: String, value: Bool, in element: XMLElement) {
        guard value else {
            return
        }
        element.setAttribute(name: name, value: "1")
    }
}
