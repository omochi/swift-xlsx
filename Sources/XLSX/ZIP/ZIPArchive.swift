import CXLSXZLib
import Foundation

enum ZIPArchive {
    static func decode(_ data: Data) throws -> [OPCFileEntry] {
        let centralDirectory = try centralDirectory(in: data)
        var entries: [OPCFileEntry] = []

        for record in centralDirectory {
            if record.fileName.hasSuffix("/") {
                entries.append(OPCFileEntry(
                    path: try OPCFilePath(string: record.fileName),
                    content: .directory([])
                ))
                continue
            }

            let compressedData = try compressedEntryData(in: data, record: record)
            let entryData = try decompress(
                compressedData,
                method: record.compressionMethod,
                uncompressedSize: record.uncompressedSize
            )
            entries.append(OPCFileEntry(
                path: try OPCFilePath(string: record.fileName),
                content: .file(entryData)
            ))
        }

        return entries
    }

    static func encode(_ entries: [OPCFileEntry]) throws -> Data {
        var data = Data()
        var centralDirectoryRecords: [ZIPCentralDirectoryRecord] = []

        for entry in zipEntries(from: entries) {
            let localHeaderOffset = data.count
            let nameData = try encodedFileName(entry.name)
            let crc = checksum(entry.data)
            let compressedData = try compress(entry.data)
            let compressedSize = try uint32(compressedData.count)
            let uncompressedSize = try uint32(entry.data.count)
            let compressionMethod: UInt16 = entry.data.isEmpty ? 0 : 8

            data.appendUInt32(0x0403_4b50)
            data.appendUInt16(20)
            data.appendUInt16(0x0800)
            data.appendUInt16(compressionMethod)
            data.appendUInt16(0)
            data.appendUInt16(0)
            data.appendUInt32(crc)
            data.appendUInt32(compressedSize)
            data.appendUInt32(uncompressedSize)
            data.appendUInt16(try uint16(nameData.count))
            data.appendUInt16(0)
            data.append(nameData)
            data.append(compressedData)

            centralDirectoryRecords.append(ZIPCentralDirectoryRecord(
                fileName: entry.name,
                fileNameData: nameData,
                compressionMethod: compressionMethod,
                crc: crc,
                compressedSize: compressedSize,
                uncompressedSize: uncompressedSize,
                localHeaderOffset: try uint32(localHeaderOffset)
            ))
        }

        let centralDirectoryOffset = data.count
        for record in centralDirectoryRecords {
            data.appendUInt32(0x0201_4b50)
            data.appendUInt16(20)
            data.appendUInt16(20)
            data.appendUInt16(0x0800)
            data.appendUInt16(record.compressionMethod)
            data.appendUInt16(0)
            data.appendUInt16(0)
            data.appendUInt32(record.crc)
            data.appendUInt32(record.compressedSize)
            data.appendUInt32(record.uncompressedSize)
            data.appendUInt16(try uint16(record.fileNameData.count))
            data.appendUInt16(0)
            data.appendUInt16(0)
            data.appendUInt16(0)
            data.appendUInt16(0)
            data.appendUInt32(0)
            data.appendUInt32(record.localHeaderOffset)
            data.append(record.fileNameData)
        }

        let centralDirectorySize = data.count - centralDirectoryOffset
        let entryCount = try uint16(centralDirectoryRecords.count)
        data.appendUInt32(0x0605_4b50)
        data.appendUInt16(0)
        data.appendUInt16(0)
        data.appendUInt16(entryCount)
        data.appendUInt16(entryCount)
        data.appendUInt32(try uint32(centralDirectorySize))
        data.appendUInt32(try uint32(centralDirectoryOffset))
        data.appendUInt16(0)

        return data
    }

    private static func centralDirectory(in data: Data) throws -> [ZIPCentralDirectoryRecord] {
        let eocdOffset = try endOfCentralDirectoryOffset(in: data)
        let entryCount = Int(try data.uint16(at: eocdOffset + 10))
        let centralDirectoryOffset = Int(try data.uint32(at: eocdOffset + 16))

        var records: [ZIPCentralDirectoryRecord] = []
        var offset = centralDirectoryOffset

        for _ in 0..<entryCount {
            guard try data.uint32(at: offset) == 0x0201_4b50 else {
                throw ZIPError.invalidArchive
            }

            let compressionMethod = try data.uint16(at: offset + 10)
            let crc = try data.uint32(at: offset + 16)
            let compressedSize = try data.uint32(at: offset + 20)
            let uncompressedSize = try data.uint32(at: offset + 24)
            let fileNameLength = Int(try data.uint16(at: offset + 28))
            let extraFieldLength = Int(try data.uint16(at: offset + 30))
            let commentLength = Int(try data.uint16(at: offset + 32))
            let localHeaderOffset = try data.uint32(at: offset + 42)

            let fileNameStart = offset + 46
            let fileNameEnd = fileNameStart + fileNameLength
            guard fileNameEnd <= data.count else {
                throw ZIPError.invalidArchive
            }
            let fileNameData = data[fileNameStart..<fileNameEnd]
            guard let fileName = String(data: fileNameData, encoding: .utf8) else {
                throw ZIPError.invalidArchive
            }

            records.append(ZIPCentralDirectoryRecord(
                fileName: fileName,
                fileNameData: fileNameData,
                compressionMethod: compressionMethod,
                crc: crc,
                compressedSize: compressedSize,
                uncompressedSize: uncompressedSize,
                localHeaderOffset: localHeaderOffset
            ))

            offset = fileNameEnd + extraFieldLength + commentLength
        }

        return records
    }

    private static func endOfCentralDirectoryOffset(in data: Data) throws -> Int {
        let minimumEOCDSize = 22
        guard data.count >= minimumEOCDSize else {
            throw ZIPError.invalidArchive
        }

        let searchStart = max(0, data.count - minimumEOCDSize - 65_535)
        var offset = data.count - minimumEOCDSize

        while offset >= searchStart {
            if try data.uint32(at: offset) == 0x0605_4b50 {
                return offset
            }
            offset -= 1
        }

        throw ZIPError.invalidArchive
    }

    private static func compressedEntryData(
        in data: Data,
        record: ZIPCentralDirectoryRecord
    ) throws -> Data {
        let offset = Int(record.localHeaderOffset)
        guard try data.uint32(at: offset) == 0x0403_4b50 else {
            throw ZIPError.invalidArchive
        }

        let fileNameLength = Int(try data.uint16(at: offset + 26))
        let extraFieldLength = Int(try data.uint16(at: offset + 28))
        let dataStart = offset + 30 + fileNameLength + extraFieldLength
        let dataEnd = dataStart + Int(record.compressedSize)
        guard dataStart <= dataEnd, dataEnd <= data.count else {
            throw ZIPError.invalidArchive
        }

        return data[dataStart..<dataEnd]
    }

    private static func decompress(
        _ data: Data,
        method: UInt16,
        uncompressedSize: UInt32
    ) throws -> Data {
        switch method {
        case 0:
            return data
        case 8:
            return try inflate(data, uncompressedSize: Int(uncompressedSize))
        default:
            throw ZIPError.unsupportedFeature("compression method \(method)")
        }
    }

    private static func inflate(_ data: Data, uncompressedSize: Int) throws -> Data {
        if uncompressedSize == 0 {
            return Data()
        }

        var output = Data(count: uncompressedSize)
        var stream = z_stream()
        let initResult = inflateInit2_(
            &stream,
            -MAX_WBITS,
            zlibVersion(),
            Int32(MemoryLayout<z_stream>.size)
        )
        guard initResult == Z_OK else {
            throw ZIPError.decompressionFailed
        }
        defer {
            inflateEnd(&stream)
        }

        let result = output.withUnsafeMutableBytes { outputBuffer in
            data.withUnsafeBytes { inputBuffer -> Int32 in
                guard let outputBaseAddress = outputBuffer.bindMemory(to: Bytef.self).baseAddress else {
                    return Z_BUF_ERROR
                }
                guard let inputBaseAddress = inputBuffer.bindMemory(to: Bytef.self).baseAddress else {
                    return Z_BUF_ERROR
                }

                stream.next_in = UnsafeMutablePointer(mutating: inputBaseAddress)
                stream.avail_in = uInt(data.count)
                stream.next_out = outputBaseAddress
                stream.avail_out = uInt(uncompressedSize)

                return CXLSXZLib.inflate(&stream, Z_FINISH)
            }
        }

        guard result == Z_STREAM_END, stream.total_out == uLong(uncompressedSize) else {
            throw ZIPError.decompressionFailed
        }

        return output
    }

    private static func compress(_ data: Data) throws -> Data {
        if data.isEmpty {
            return Data()
        }

        let outputCapacity = Int(try uint32(Int(compressBound(uLong(data.count)))))
        var output = Data(count: outputCapacity)
        var stream = z_stream()
        let initResult = deflateInit2_(
            &stream,
            Z_DEFAULT_COMPRESSION,
            Z_DEFLATED,
            -MAX_WBITS,
            MAX_MEM_LEVEL,
            Z_DEFAULT_STRATEGY,
            zlibVersion(),
            Int32(MemoryLayout<z_stream>.size)
        )
        guard initResult == Z_OK else {
            throw ZIPError.compressionFailed
        }
        defer {
            deflateEnd(&stream)
        }

        let result = output.withUnsafeMutableBytes { outputBuffer in
            data.withUnsafeBytes { inputBuffer -> Int32 in
                guard let outputBaseAddress = outputBuffer.bindMemory(to: Bytef.self).baseAddress else {
                    return Z_BUF_ERROR
                }
                guard let inputBaseAddress = inputBuffer.bindMemory(to: Bytef.self).baseAddress else {
                    return Z_BUF_ERROR
                }

                stream.next_in = UnsafeMutablePointer(mutating: inputBaseAddress)
                stream.avail_in = uInt(data.count)
                stream.next_out = outputBaseAddress
                stream.avail_out = uInt(outputCapacity)

                return CXLSXZLib.deflate(&stream, Z_FINISH)
            }
        }

        guard result == Z_STREAM_END else {
            throw ZIPError.compressionFailed
        }

        output.count = Int(stream.total_out)
        return output
    }

    private static func zipEntries(from entries: [OPCFileEntry]) -> [ZIPEntry] {
        entries.map { entry in
            switch entry.content {
            case .directory:
                ZIPEntry(
                    name: entry.path.components.joined(separator: "/") + "/",
                    data: Data()
                )

            case let .file(data):
                ZIPEntry(
                    name: entry.path.components.joined(separator: "/"),
                    data: data
                )
            }
        }
    }

    private static func encodedFileName(_ name: String) throws -> Data {
        guard !name.isEmpty, let data = name.data(using: .utf8) else {
            throw ZIPError.invalidArchive
        }
        _ = try uint16(data.count)
        return data
    }

    private static func checksum(_ data: Data) -> UInt32 {
        let initial = crc32(0, nil, 0)
        return data.withUnsafeBytes { buffer in
            guard let baseAddress = buffer.bindMemory(to: Bytef.self).baseAddress else {
                return UInt32(initial)
            }
            return UInt32(crc32(initial, baseAddress, uInt(data.count)))
        }
    }

    private static func uint16(_ value: Int) throws -> UInt16 {
        guard value >= 0, value <= Int(UInt16.max) else {
            throw ZIPError.archiveTooLarge
        }
        return UInt16(value)
    }

    private static func uint32(_ value: Int) throws -> UInt32 {
        guard value >= 0, value <= Int(UInt32.max) else {
            throw ZIPError.archiveTooLarge
        }
        return UInt32(value)
    }
}

private extension Data {
    mutating func appendUInt16(_ value: UInt16) {
        append(UInt8(value & 0x00ff))
        append(UInt8((value >> 8) & 0x00ff))
    }

    mutating func appendUInt32(_ value: UInt32) {
        append(UInt8(value & 0x0000_00ff))
        append(UInt8((value >> 8) & 0x0000_00ff))
        append(UInt8((value >> 16) & 0x0000_00ff))
        append(UInt8((value >> 24) & 0x0000_00ff))
    }

    func uint16(at offset: Int) throws -> UInt16 {
        guard offset >= 0, offset + 2 <= count else {
            throw ZIPError.invalidArchive
        }
        return UInt16(self[offset])
            | (UInt16(self[offset + 1]) << 8)
    }

    func uint32(at offset: Int) throws -> UInt32 {
        guard offset >= 0, offset + 4 <= count else {
            throw ZIPError.invalidArchive
        }
        return UInt32(self[offset])
            | (UInt32(self[offset + 1]) << 8)
            | (UInt32(self[offset + 2]) << 16)
            | (UInt32(self[offset + 3]) << 24)
    }
}
