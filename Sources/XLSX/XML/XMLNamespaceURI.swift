import Synchronization

public struct XMLNamespaceURI: Sendable & Hashable {
    private final class Storage: Sendable {
        init(_ string: String) {
            self.string = string
        }

        let string: String
    }

    private static let cache = Mutex<[String: Storage]>([:])

    public init(_ string: String) {
        self.storage = Self.storage(for: string)
    }

    private let storage: Storage

    public var string: String {
        storage.string
    }

    public static func == (lhs: XMLNamespaceURI, rhs: XMLNamespaceURI) -> Bool {
        lhs.storage === rhs.storage
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(storage))
    }

    private static func storage(for string: String) -> Storage {
        cache.withLock { cache in
            if let storage = cache[string] {
                return storage
            }

            let storage = Storage(string)
            cache[string] = storage
            return storage
        }
    }
}
