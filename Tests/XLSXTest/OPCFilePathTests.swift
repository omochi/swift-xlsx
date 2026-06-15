import Testing
import XLSX

@Suite
struct OPCFilePathTests {
    @Test func parsesAbsoluteAndRelativePaths() throws {
        #expect(try OPCFilePath(string: "/xl/workbook.xml").description == "/xl/workbook.xml")
        #expect(try OPCFilePath(string: "worksheets/sheet1.xml").description == "worksheets/sheet1.xml")
    }

    @Test func ignoresTrailingSlashWhenParsing() throws {
        #expect(try OPCFilePath(string: "/xl/").description == "/xl")
        #expect(try OPCFilePath(string: "xl/").description == "xl")
    }

    @Test func ignoresRepeatedSeparatorsWhenParsing() throws {
        #expect(try OPCFilePath(string: "/xl///worksheets/sheet1.xml").description == "/xl/worksheets/sheet1.xml")
        #expect(try OPCFilePath(string: "xl///worksheets/sheet1.xml").description == "xl/worksheets/sheet1.xml")
    }

    @Test func normalizesRelativePath() throws {
        let path = try OPCFilePath(string: "a/./b/../c/../../d")

        #expect(try path.normalized().description == "d")
    }

    @Test func preservesLeadingParentReferencesWhenNormalizingRelativePath() throws {
        let path = try OPCFilePath(string: "a/../../b")

        #expect(try path.normalized().description == "../b")
    }

    @Test func rejectsParentReferenceAboveAbsoluteRootWhenNormalizing() throws {
        do {
            _ = try OPCFilePath(string: "/../xl").normalized()
            Issue.record("Expected invalid path error.")
        } catch let error as OPCError {
            #expect(error == .invalidPath("/../xl"))
        }
    }

    @Test func resolvesRelativePathAgainstSourcePath() throws {
        let path = try OPCFilePath(string: "../sharedStrings.xml")
            .resolved(relativeTo: OPCFilePath(string: "/xl/workbook.xml"))

        #expect(path.description == "/sharedStrings.xml")
    }

    @Test func makesRelationshipTargetRelativeToSourcePath() throws {
        #expect(try OPCFilePath(string: "/xl/workbook.xml")
            .relationshipTarget(relativeTo: .packageRoot) == "xl/workbook.xml")
        #expect(try OPCFilePath(string: "/xl/worksheets/sheet1.xml")
            .relationshipTarget(relativeTo: OPCFilePath(string: "/xl/workbook.xml")) == "worksheets/sheet1.xml")
    }
}
