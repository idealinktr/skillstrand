import Foundation
import SkillstrandCore
import SkillstrandEntities
import SkillstrandIntents
import SkillstrandShortcuts

public struct ExampleSkill: Sendable, Equatable, Identifiable {
    public var name: String
    public var title: String
    public var summary: String
    public var intent: IntentBlueprint
    public var entity: EntityBlueprint?
    public var shortcut: ShortcutBlueprint

    public var id: String { name }

    public init(
        name: String,
        title: String,
        summary: String,
        intent: IntentBlueprint,
        entity: EntityBlueprint? = nil,
        shortcut: ShortcutBlueprint
    ) {
        self.name = name
        self.title = title
        self.summary = summary
        self.intent = intent
        self.entity = entity
        self.shortcut = shortcut
    }
}

public enum ExampleSkillCatalog {
    public static let all: [ExampleSkill] = [
        ExampleSkill(
            name: CaptureToTaskSkill.name,
            title: "Capture to task",
            summary: "Save a dictated to-do after confirming the title, then ask about a due date.",
            intent: CaptureToTaskSkill.blueprint(),
            shortcut: CaptureToTaskSkill.shortcut()
        ),
        ExampleSkill(
            name: SearchAndOpenSkill.name,
            title: "Search and open",
            summary: "Find a library item by name and open it, choosing when several titles match.",
            intent: SearchAndOpenSkill.blueprint(),
            entity: SearchAndOpenSkill.entityBlueprint(),
            shortcut: SearchAndOpenSkill.shortcut()
        ),
        ExampleSkill(
            name: SummarizeAndShareSkill.name,
            title: "Summarize and share",
            summary: "Shorten one note, pick a destination, and confirm before anything is sent.",
            intent: SummarizeAndShareSkill.blueprint(),
            entity: SummarizeAndShareSkill.entityBlueprint(),
            shortcut: SummarizeAndShareSkill.shortcut()
        ),
        ExampleSkill(
            name: ScheduledReminderSkill.name,
            title: "Scheduled reminder",
            summary: "Turn a vague time such as Friday into one confirmed reminder.",
            intent: ScheduledReminderSkill.blueprint(),
            shortcut: ScheduledReminderSkill.shortcut()
        ),
    ]

    public static func bundledDocuments() throws -> [SkillDocument] {
        if let root = Bundle.module.url(forResource: "Skills", withExtension: nil) {
            return try SkillBundleValidator.load(at: root)
        }
        if let root = Bundle.module.resourceURL?.appendingPathComponent("Skills", isDirectory: true) {
            return try SkillBundleValidator.load(at: root)
        }
        throw SkillDocumentError.missingSkillsDirectory("Skills")
    }
}
