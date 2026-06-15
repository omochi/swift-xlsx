import Foundation

public protocol OPCFile {
    init(data: Data) throws
    func data() throws -> Data
}
