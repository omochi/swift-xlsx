import MemberwiseInit
import Foundation

@MemberwiseInit
struct ZIPCentralDirectoryRecord: Sendable {
    var fileName: String
    var fileNameData: Data
    var compressionMethod: UInt16
    var crc: UInt32
    var compressedSize: UInt32
    var uncompressedSize: UInt32
    var localHeaderOffset: UInt32
}
