extension XMLUtils {
    static func boolString(value: Bool) -> String {
        value ? "1" : "0"
    }

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

    static func setIntAttribute(name: String, value: Int?, in element: XMLElement) {
        guard let value else {
            element.removeAttribute(name: name)
            return
        }
        element.setAttribute(name: name, value: String(value))
    }

    static func setDoubleAttribute(name: String, value: Double?, in element: XMLElement) {
        guard let value else {
            element.removeAttribute(name: name)
            return
        }
        element.setAttribute(name: name, value: String(value))
    }

    static func setStringAttribute(name: String, value: String?, in element: XMLElement) {
        guard let value else {
            element.removeAttribute(name: name)
            return
        }
        element.setAttribute(name: name, value: value)
    }

    static func setBoolAttribute(name: String, value: Bool?, in element: XMLElement) {
        guard let value else {
            element.removeAttribute(name: name)
            return
        }
        element.setAttribute(name: name, value: boolString(value: value))
    }
}
