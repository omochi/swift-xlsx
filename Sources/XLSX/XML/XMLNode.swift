public class XMLNode {
    public init() {}

    public weak var parent: XMLNode?

    public var kind: XMLNodeKind {
        fatalError("Subclasses must provide a node kind.")
    }

    public var children: [XMLNode] {
        get { [] }
        set {}
    }

    public func appendChild(_ child: XMLNode) {
        child.parent = self
        children.append(child)
    }

    @discardableResult
    public func removeChild(_ child: XMLNode) -> XMLNode? {
        guard let index = children.firstIndex(where: { $0 === child }) else {
            return nil
        }

        let removed = children.remove(at: index)
        removed.parent = nil
        return removed
    }
}
