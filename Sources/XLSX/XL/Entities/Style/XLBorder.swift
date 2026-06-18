import MemberwiseInit
import XLSXXML

@MemberwiseInit(.public)
public struct XLBorder: Sendable & Hashable {
    @MemberwiseInit(.public)
    public struct Line: Sendable & Hashable {
        public init(element: XMLElement) {
            self.init(
                style: element.attribute(name: "style").flatMap(XLBorder.LineStyle.init(rawValue:)),
                color: element.elements(name: "color").first.flatMap(XLColor.init(element:))
            )
        }

        public var style: LineStyle? = nil
        public var color: XLColor? = nil

        public func xmlElement(name: String) -> XMLElement {
            let element = XMLElement(name: XMLName(name: name))
            XMLUtils.setStringAttribute(name: "style", value: style?.rawValue, in: element)

            if let color {
                element.appendChild(color.xmlElement(name: "color"))
            }

            return element
        }
    }

    @MemberwiseInit(.public)
    public struct Diagonal: Sendable & Hashable {
        public var directions: DiagonalDirections = []
        public var line: Line
    }

    public struct DiagonalDirections: Sendable & OptionSet & Hashable {
        public init(rawValue: Int) {
            self.rawValue = rawValue
        }

        public var rawValue: Int

        public static let up = Self(rawValue: 1 << 0)
        public static let down = Self(rawValue: 1 << 1)
    }

    public enum LineStyle: String, Sendable & Hashable {
        case none
        case thin
        case medium
        case dashed
        case dotted
        case thick
        case double
        case hair
        case mediumDashed
        case dashDot
        case mediumDashDot
        case dashDotDot
        case mediumDashDotDot
        case slantDashDot
    }

    public init(element: XMLElement) {
        self.init(
            outline: Self.boolAttribute(name: "outline", in: element),
            start: Self.line(name: "start", in: element),
            end: Self.line(name: "end", in: element),
            left: Self.line(name: "left", in: element),
            right: Self.line(name: "right", in: element),
            top: Self.line(name: "top", in: element),
            bottom: Self.line(name: "bottom", in: element),
            diagonal: Self.diagonal(in: element),
            vertical: Self.line(name: "vertical", in: element),
            horizontal: Self.line(name: "horizontal", in: element)
        )
    }

    public var outline: Bool? = nil
    public var start: Line? = nil
    public var end: Line? = nil
    public var left: Line? = nil
    public var right: Line? = nil
    public var top: Line? = nil
    public var bottom: Line? = nil
    public var diagonal: Diagonal? = nil
    public var vertical: Line? = nil
    public var horizontal: Line? = nil

    public func xmlElement() -> XMLElement {
        let element = XMLElement(name: XMLName(name: "border"))
        XMLUtils.setBoolAttribute(name: "outline", value: outline, in: element)
        appendLine(name: "start", line: start, to: element)
        appendLine(name: "end", line: end, to: element)
        appendLine(name: "left", line: left, to: element)
        appendLine(name: "right", line: right, to: element)
        appendLine(name: "top", line: top, to: element)
        appendLine(name: "bottom", line: bottom, to: element)
        appendDiagonal(to: element)
        appendLine(name: "vertical", line: vertical, to: element)
        appendLine(name: "horizontal", line: horizontal, to: element)
        return element
    }

    private static func boolAttribute(name: String, in element: XMLElement) -> Bool? {
        guard let value = element.attribute(name: name) else {
            return nil
        }

        return XMLUtils.boolValue(string: value)
    }

    private static func line(name: String, in element: XMLElement) -> Line? {
        guard let lineElement = element.elements(name: name).first else {
            return nil
        }

        return Line(element: lineElement)
    }

    private static func diagonal(in element: XMLElement) -> Diagonal? {
        guard let diagonalElement = element.elements(name: "diagonal").first else {
            return nil
        }

        var directions: DiagonalDirections = []
        if XMLUtils.boolAttribute(name: "diagonalUp", in: element) {
            directions.insert(.up)
        }
        if XMLUtils.boolAttribute(name: "diagonalDown", in: element) {
            directions.insert(.down)
        }

        return Diagonal(
            directions: directions,
            line: Line(element: diagonalElement)
        )
    }

    private func appendLine(name: String, line: Line?, to element: XMLElement) {
        guard let line else {
            return
        }

        element.appendChild(line.xmlElement(name: name))
    }

    private func appendDiagonal(to element: XMLElement) {
        guard let diagonal, !diagonal.directions.isEmpty else {
            return
        }

        XMLUtils.setBoolAttribute(
            name: "diagonalUp",
            value: diagonal.directions.contains(.up) ? true : nil,
            in: element
        )
        XMLUtils.setBoolAttribute(
            name: "diagonalDown",
            value: diagonal.directions.contains(.down) ? true : nil,
            in: element
        )
        element.appendChild(diagonal.line.xmlElement(name: "diagonal"))
    }
}
