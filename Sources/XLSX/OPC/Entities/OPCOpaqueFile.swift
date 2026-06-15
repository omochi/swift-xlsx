import Foundation

public struct OPCOpaqueFile: OPCFile {
    public init(data: Data) {
        self.storage = data
    }

    private var storage: Data

    public func data() -> Data {
        storage
    }
}
