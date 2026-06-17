extension XMLUtils {
    public static func boolString(value: Bool) -> String {
        value ? "1" : "0"
    }

    public static func boolValue(string: String) -> Bool? {
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

    public static func intAttribute(name: String, in element: XMLElement) -> Int? {
        guard let value = element.attribute(name: name) else {
            return nil
        }
        return Int(value)
    }

    public static func doubleAttribute(name: String, in element: XMLElement) -> Double? {
        guard let value = element.attribute(name: name) else {
            return nil
        }
        return Double(value)
    }

    public static func boolAttribute(
        name: String,
        in element: XMLElement,
        defaultValue: Bool = false
    ) -> Bool {
        guard let value = element.attribute(name: name) else {
            return defaultValue
        }
        return boolValue(string: value) ?? false
    }

    public static func setIntAttribute(name: String, value: Int?, in element: XMLElement) {
        guard let value else {
            element.removeAttribute(name: name)
            return
        }
        element.setAttribute(name: name, value: String(value))
    }

    public static func setDoubleAttribute(name: String, value: Double?, in element: XMLElement) {
        guard let value else {
            element.removeAttribute(name: name)
            return
        }
        element.setAttribute(name: name, value: String(value))
    }

    public static func setStringAttribute(name: String, value: String?, in element: XMLElement) {
        guard let value else {
            element.removeAttribute(name: name)
            return
        }
        element.setAttribute(name: name, value: value)
    }

    public static func setBoolAttribute(name: String, value: Bool?, in element: XMLElement) {
        guard let value else {
            element.removeAttribute(name: name)
            return
        }
        element.setAttribute(name: name, value: boolString(value: value))
    }
}
