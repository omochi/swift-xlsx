public class XMLNode {
    public init() {}

    public private(set) weak var parent: XMLNode?

    public var kind: XMLNodeKind {
        fatalError("Subclasses must provide a node kind.")
    }

    public var children: [XMLNode] {
        get { [] }
        set {}
    }

    public func clone() -> Self {
        fatalError("Subclasses must provide a clone.")
    }

    public func namespaceURI(for prefix: String? = nil) -> XMLNamespaceURI? {
        parent?.namespaceURI(for: prefix)
    }

    public func appendChild(_ child: XMLNode) {
        child._setParent(self)
        children.append(child)
    }

    @discardableResult
    public func removeChild(_ child: XMLNode) -> XMLNode? {
        guard let index = children.firstIndex(where: { $0 === child }) else {
            return nil
        }

        let removed = children.remove(at: index)
        removed._setParent(nil)
        return removed
    }

    func _setParent(_ parent: XMLNode?) {
        self.parent = parent
    }
}
