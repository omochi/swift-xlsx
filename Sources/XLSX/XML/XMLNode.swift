public class XMLNode {
    public init() {}

    public private(set) weak var parent: XMLNode?

    public var kind: XMLNodeKind {
        fatalError("Subclasses must provide a node kind.")
    }

    public var children: [XMLNode] {
        get { _children }
        set { replaceChildren(newValue) }
    }

    var _children: [XMLNode] {
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
        _children.append(child)
    }

    @discardableResult
    public func removeChild(_ child: XMLNode) -> XMLNode? {
        guard let index = _children.firstIndex(where: { $0 === child }) else {
            return nil
        }

        let removed = _children.remove(at: index)
        removed._setParent(nil)
        return removed
    }

    func _setParent(_ parent: XMLNode?) {
        self.parent = parent
    }

    private func replaceChildren(_ newChildren: [XMLNode]) {
        for child in _children {
            child._setParent(nil)
        }

        for child in newChildren {
            if let parent = child.parent, parent !== self {
                _ = parent.removeChild(child)
            }
            child._setParent(self)
        }

        _children = newChildren
    }
}
