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

    @Test func ensureOverrideRemovesOverrideWhenContentTypeIsNil() throws {
        let path = try OPCFilePath(string: "/xl/styles.xml")
        var contentTypes = OPCContentTypesFile(overrides: [
            path: OPCContentTypes.styles,
        ])

        contentTypes.ensureOverride(partName: path, contentType: nil)

        #expect(contentTypes.overrides[path] == nil)
    }

    @Test func rejectsRelationshipsFileWithoutRelationshipsRoot() throws {
        do {
            _ = try OPCRelsFile(data: Data("<Root/>".utf8))
            Issue.record("Expected invalid relationships file error.")
        } catch let error as OPCError {
            #expect(error == .invalidRelationshipsFile)
        }
    }

    @Test func ensureRelationshipByTypeUpdatesExistingTarget() throws {
        var relationships = OPCRelsFile(relationships: [
            OPCRelationship(id: "rId1", type: "known", target: "old.xml"),
        ])

        guard let relationship = relationships.ensureRelationship(type: "known", target: "new.xml") else {
            Issue.record("Expected relationship.")
            return
        }

        #expect(relationship.id == "rId1")
        #expect(relationship.type == "known")
        #expect(relationship.target == "new.xml")
        #expect(relationships.relationships.count == 1)
        #expect(relationships.relationships.first?.id == "rId1")
        #expect(relationships.relationships.first?.type == "known")
        #expect(relationships.relationships.first?.target == "new.xml")
    }

    @Test func ensureRelationshipByTypeRemovesExistingRelationshipWhenTargetIsNil() throws {
        var relationships = OPCRelsFile(relationships: [
            OPCRelationship(id: "rId1", type: "known", target: "old.xml"),
            OPCRelationship(id: "rId2", type: "other", target: "other.xml"),
        ])

        let relationship = relationships.ensureRelationship(type: "known", target: nil)

        #expect(relationship == nil)
        #expect(relationships.relationships.count == 1)
        #expect(relationships.relationships.first?.id == "rId2")
        #expect(relationships.relationships.first?.type == "other")
        #expect(relationships.relationships.first?.target == "other.xml")
    }

    @Test func rejectsStylesFileWithoutStyleSheetRoot() throws {
        do {
            _ = try XLStylesFile(data: Data("<Root/>".utf8))
            Issue.record("Expected invalid styles file error.")
        } catch let error as OPCError {
            #expect(error == .invalidStylesFile)
        }
    }
}
