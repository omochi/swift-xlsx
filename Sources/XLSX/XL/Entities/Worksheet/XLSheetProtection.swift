import struct Foundation.Data
import Crypto
import MemberwiseInit
import XLSXXML

@MemberwiseInit(.public)
public struct XLSheetProtection: Sendable & Hashable {
    public enum Algorithm: String, Sendable & Hashable {
        case sha512 = "SHA-512"
    }

    @MemberwiseInit(.public)
    public struct PasswordHashInfo: Sendable & Hashable {
        public init(element: XMLElement) {
            self.algorithmName = element.attribute(name: "algorithmName")
            self.hashValue = element.attribute(name: "hashValue").flatMap { Data(base64Encoded: $0) }
            self.saltValue = element.attribute(name: "saltValue").flatMap { Data(base64Encoded: $0) }
            self.spinCount = element.attribute(name: "spinCount")
        }

        public var algorithmName: String? = nil
        public var hashValue: Data? = nil
        public var saltValue: Data? = nil
        public var spinCount: String? = nil

        public static func generate(
            password: String,
            algorithm: Algorithm,
            spinCount: UInt32 = 100_000,
            salt: Data = randomSalt()
        ) -> Self {
            switch algorithm {
            case .sha512:
                return Self(
                    algorithmName: algorithm.rawValue,
                    hashValue: sha512HashValue(password: password, spinCount: spinCount, salt: salt),
                    saltValue: salt,
                    spinCount: String(spinCount)
                )
            }
        }

        public static func randomSalt(byteCount: Int = 16) -> Data {
            Data((0..<byteCount).map { _ in UInt8.random(in: .min ... .max) })
        }

        func write(to xmlElement: XMLElement) {
            XMLUtils.setStringAttribute(name: "algorithmName", value: algorithmName, in: xmlElement)
            XMLUtils.setStringAttribute(name: "hashValue", value: hashValue?.base64EncodedString(), in: xmlElement)
            XMLUtils.setStringAttribute(name: "saltValue", value: saltValue?.base64EncodedString(), in: xmlElement)
            XMLUtils.setStringAttribute(name: "spinCount", value: spinCount, in: xmlElement)
        }

        private static func sha512HashValue(password: String, spinCount: UInt32, salt: Data) -> Data {
            var hashValue = Data(SHA512.hash(data: salt + password.utf16LittleEndianData))

            for index in UInt32(0)..<spinCount {
                var bytes = hashValue
                bytes.append(contentsOf: index.littleEndianBytes)
                hashValue = Data(SHA512.hash(data: bytes))
            }

            return hashValue
        }
    }

    public init(element: XMLElement) {
        self.sheet = XMLUtils.boolAttribute(name: "sheet", in: element, defaultValue: true)
        self.objects = XMLUtils.boolAttribute(name: "objects", in: element, defaultValue: true)
        self.scenarios = XMLUtils.boolAttribute(name: "scenarios", in: element, defaultValue: true)
        self.formatCells = XMLUtils.boolAttribute(name: "formatCells", in: element, defaultValue: true)
        self.formatColumns = XMLUtils.boolAttribute(name: "formatColumns", in: element, defaultValue: true)
        self.formatRows = XMLUtils.boolAttribute(name: "formatRows", in: element, defaultValue: true)
        self.insertColumns = XMLUtils.boolAttribute(name: "insertColumns", in: element, defaultValue: true)
        self.insertRows = XMLUtils.boolAttribute(name: "insertRows", in: element, defaultValue: true)
        self.insertHyperlinks = XMLUtils.boolAttribute(name: "insertHyperlinks", in: element, defaultValue: true)
        self.deleteColumns = XMLUtils.boolAttribute(name: "deleteColumns", in: element, defaultValue: true)
        self.deleteRows = XMLUtils.boolAttribute(name: "deleteRows", in: element, defaultValue: true)
        self.selectLockedCells = XMLUtils.boolAttribute(name: "selectLockedCells", in: element, defaultValue: false)
        self.selectUnlockedCells = XMLUtils.boolAttribute(name: "selectUnlockedCells", in: element, defaultValue: false)
        self.sort = XMLUtils.boolAttribute(name: "sort", in: element, defaultValue: true)
        self.autoFilter = XMLUtils.boolAttribute(name: "autoFilter", in: element, defaultValue: true)
        self.pivotTables = XMLUtils.boolAttribute(name: "pivotTables", in: element, defaultValue: true)
        self.password = element.attribute(name: "password")
        self.passwordHashInfo = PasswordHashInfo(element: element)
    }

    public var sheet = true
    public var objects = true
    public var scenarios = true
    public var formatCells = true
    public var formatColumns = true
    public var formatRows = true
    public var insertColumns = true
    public var insertRows = true
    public var insertHyperlinks = true
    public var deleteColumns = true
    public var deleteRows = true
    public var selectLockedCells = false
    public var selectUnlockedCells = false
    public var sort = true
    public var autoFilter = true
    public var pivotTables = true
    public var password: String? = nil
    public var passwordHashInfo: PasswordHashInfo = PasswordHashInfo()

    func write(to xmlElement: XMLElement) {
        xmlElement.attributes = []
        XMLUtils.setBoolAttribute(name: "sheet", value: sheet, in: xmlElement)
        XMLUtils.setBoolAttribute(name: "objects", value: objects, in: xmlElement)
        XMLUtils.setBoolAttribute(name: "scenarios", value: scenarios, in: xmlElement)
        XMLUtils.setBoolAttribute(name: "formatCells", value: formatCells, default: true, in: xmlElement)
        XMLUtils.setBoolAttribute(name: "formatColumns", value: formatColumns, default: true, in: xmlElement)
        XMLUtils.setBoolAttribute(name: "formatRows", value: formatRows, default: true, in: xmlElement)
        XMLUtils.setBoolAttribute(name: "insertColumns", value: insertColumns, default: true, in: xmlElement)
        XMLUtils.setBoolAttribute(name: "insertRows", value: insertRows, default: true, in: xmlElement)
        XMLUtils.setBoolAttribute(name: "insertHyperlinks", value: insertHyperlinks, default: true, in: xmlElement)
        XMLUtils.setBoolAttribute(name: "deleteColumns", value: deleteColumns, default: true, in: xmlElement)
        XMLUtils.setBoolAttribute(name: "deleteRows", value: deleteRows, default: true, in: xmlElement)
        XMLUtils.setBoolAttribute(name: "selectLockedCells", value: selectLockedCells, default: false, in: xmlElement)
        XMLUtils.setBoolAttribute(name: "selectUnlockedCells", value: selectUnlockedCells, default: false, in: xmlElement)
        XMLUtils.setBoolAttribute(name: "sort", value: sort, default: true, in: xmlElement)
        XMLUtils.setBoolAttribute(name: "autoFilter", value: autoFilter, default: true, in: xmlElement)
        XMLUtils.setBoolAttribute(name: "pivotTables", value: pivotTables, default: true, in: xmlElement)
        XMLUtils.setStringAttribute(name: "password", value: password, in: xmlElement)
        passwordHashInfo.write(to: xmlElement)
    }
}

private extension String {
    var utf16LittleEndianData: Data {
        var data = Data()
        data.reserveCapacity(utf16.count * 2)

        for codeUnit in utf16 {
            data.append(contentsOf: codeUnit.littleEndianBytes)
        }

        return data
    }
}

private extension FixedWidthInteger {
    var littleEndianBytes: [UInt8] {
        withUnsafeBytes(of: littleEndian) { Array($0) }
    }
}
