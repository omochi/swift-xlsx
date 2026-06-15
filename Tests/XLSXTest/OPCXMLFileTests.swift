import Foundation
import Testing
import XLSX

@Suite
struct OPCXMLFileTests {
    @Test func rejectsContentTypesFileWithoutTypesRoot() throws {
        do {
            _ = try OPCContentTypesFile(data: Data("<Root/>".utf8))
            Issue.record("Expected invalid content types file error.")
        } catch let error as OPCError {
            #expect(error == .invalidContentTypesFile)
        }
    }

    @Test func rejectsRelationshipsFileWithoutRelationshipsRoot() throws {
        do {
            _ = try OPCRelsFile(data: Data("<Root/>".utf8))
            Issue.record("Expected invalid relationships file error.")
        } catch let error as OPCError {
            #expect(error == .invalidRelationshipsFile)
        }
    }
}
