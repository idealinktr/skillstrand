import XCTest
@testable import SkillstrandCore

final class SkillDocumentTests: XCTestCase {
    func testParsesTheDocumentedFrontMatter() throws {
        let raw = """
        ---
        name: flight-add
        description: This skill guides the user through adding a flight.
        ---

        Call the add-flight tool after the person confirms the flight number.
        """
        let document = try SkillDocumentParser.parse(raw, directoryName: "flight-add")
        XCTAssertEqual(document.name, "flight-add")
        XCTAssertEqual(document.summary, "This skill guides the user through adding a flight.")
        XCTAssertTrue(document.body.contains("add-flight"))
    }

    func testRejectsUnsupportedFieldsAndBadNames() {
        XCTAssertThrowsError(
            try SkillDocumentParser.parse("---\nname: flight-add\nwhen: now\ndescription: Adds a flight.\n---\nBody.\n")
        ) { error in
            XCTAssertEqual(error as? SkillDocumentError, .unsupportedField("when"))
        }
        XCTAssertThrowsError(try SkillDocumentParser.parse("---\nname: -bad\ndescription: Adds a flight.\n---\nBody.\n"))
        XCTAssertThrowsError(try SkillDocumentParser.parse("---\nname: bad--name\ndescription: Adds a flight.\n---\nBody.\n"))
        XCTAssertThrowsError(try SkillDocumentParser.parse("---\nname: Bad\ndescription: Adds a flight.\n---\nBody.\n"))
        let long = String(repeating: "a", count: 65)
        XCTAssertThrowsError(try SkillDocumentParser.parse("---\nname: \(long)\ndescription: Adds a flight.\n---\nBody.\n"))
    }

    func testRejectsALongDescriptionAnEmptyBodyAndADirectoryMismatch() {
        let long = String(repeating: "d", count: 1025)
        XCTAssertThrowsError(
            try SkillDocumentParser.parse("---\nname: flight-add\ndescription: \(long)\n---\nBody.\n")
        )
        XCTAssertThrowsError(
            try SkillDocumentParser.parse("---\nname: flight-add\ndescription: Adds a flight.\n---\n\n")
        ) { error in
            XCTAssertEqual(error as? SkillDocumentError, .emptyBody)
        }
        XCTAssertThrowsError(
            try SkillDocumentParser.parse(
                "---\nname: flight-add\ndescription: Adds a flight.\n---\nBody.\n",
                directoryName: "other"
            )
        )
    }

    func testBundleRejectsExtraFiles() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        let skill = root.appendingPathComponent("Skills/flight-add", isDirectory: true)
        try FileManager.default.createDirectory(at: skill, withIntermediateDirectories: true)
        try """
        ---
        name: flight-add
        description: Adds a flight after confirmation.
        ---
        Call the tool.
        """.write(to: skill.appendingPathComponent("SKILL.md"), atomically: true, encoding: .utf8)
        try "nope".write(to: skill.appendingPathComponent("NOTES.md"), atomically: true, encoding: .utf8)
        let bundle = root.appendingPathComponent("Skills.skillsbundle")
        try FileManager.default.createDirectory(at: bundle, withIntermediateDirectories: true)
        try FileManager.default.copyItem(at: root.appendingPathComponent("Skills"), to: bundle.appendingPathComponent("Skills"))
        XCTAssertThrowsError(try SkillBundleValidator.load(at: bundle))
        try FileManager.default.removeItem(at: root)
    }
}
