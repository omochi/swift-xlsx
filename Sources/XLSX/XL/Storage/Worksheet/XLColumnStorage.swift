import MemberwiseInit

@MemberwiseInit(.public)
public final class XLColumnStorage {
    public init(columnElement: XMLElement) {
        self.width = XMLUtils.doubleAttribute(name: "width", in: columnElement)
    }

    public var width: Double?

    public func write(to columnElement: XMLElement, columnNumber: Int) {
        XMLUtils.setIntAttribute(name: "min", value: columnNumber, in: columnElement)
        XMLUtils.setIntAttribute(name: "max", value: columnNumber, in: columnElement)
        XMLUtils.setDoubleAttribute(name: "width", value: width, in: columnElement)
        XMLUtils.setBoolAttribute(name: "customWidth", value: width == nil ? nil : true, in: columnElement)
    }

    public func clone() -> XLColumnStorage {
        XLColumnStorage(width: width)
    }
}
