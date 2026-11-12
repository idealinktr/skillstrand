import Foundation
import SkillstrandCore
import SkillstrandEntities
import SkillstrandIntents
import SkillstrandShortcuts

public struct NoteRecord: Sendable, Equatable, Identifiable, Hashable {
    public var id: String
    public var title: String
    public var body: String

    public init(id: String, title: String, body: String) {
        self.id = id
        self.title = title
        self.body = body
    }
}

public enum ShareDestination: String, Sendable, Equatable, CaseIterable, Identifiable {
    case messages
    case mail
    case copy

    public var id: String { rawValue }

    public var label: String {
        switch self {
        case .messages: "Messages"
        case .mail: "Mail"
        case .copy: "Copy"
        }
    }
}

public struct SummarizeAndShareInput: Sendable, Equatable {
    public var note: NoteRecord?
    public var destination: ShareDestination?
    public var shareConfirmed: ConfirmationAnswer?
    public var summaryLimit: Int

    public init(
        note: NoteRecord? = nil,
        destination: ShareDestination? = nil,
        shareConfirmed: ConfirmationAnswer? = nil,
        summaryLimit: Int = 180
    ) {
        self.note = note
        self.destination = destination
        self.shareConfirmed = shareConfirmed
        self.summaryLimit = summaryLimit
    }
}

/// Summarize one note, pick where it goes, and confirm before sharing.
public enum SummarizeAndShareSkill {
    public static let name = "summarize-and-share"
    public static let intentName = "ShareSummary"

    public static let starterNotes: [NoteRecord] = [
        NoteRecord(
            id: "north-fence",
            title: "North fence",
            body: "The north fence needs new staples before the wind turns. Bring the short twine, not the baling coil. The gate post is sound."
        ),
        NoteRecord(
            id: "market-day",
            title: "Market day",
            body: "Leave by seven. The early table is the one under the plane tree. Hold back the kiln cups until the second firing is priced."
        ),
    ]

    public static func blueprint() -> IntentBlueprint {
        IntentBlueprint(
            name: intentName,
            title: "Share Summary",
            summary: "Shares a short summary after the person picks a destination and confirms."
        ) {
            ParameterSpec(
                name: "note",
                title: "Note",
                summary: "The note to summarize.",
                type: .entity,
                entityType: "Note"
            )
            ParameterSpec(
                name: "destination",
                title: "Destination",
                summary: "Messages, Mail, or Copy.",
                type: .string
            )
            ParameterSpec(
                name: "summary",
                title: "Summary",
                summary: "The shortened note that will be shared.",
                type: .string
            )
        }
    }

    public static func entityBlueprint() -> EntityBlueprint {
        EntityBlueprint(
            typeName: "Note",
            displayName: "Note",
            identifierComment: "Stable note id.",
            properties: [
                PropertyConvention(
                    name: "title",
                    title: "Title",
                    summary: "The note title.",
                    spotlightKey: .title,
                    searchable: true
                ),
                PropertyConvention(
                    name: "body",
                    title: "Body",
                    summary: "The full note. The summary sent onward is shorter.",
                    spotlightKey: .contentDescription,
                    searchable: true,
                    visibility: .internalOnly
                ),
            ],
            stringQuery: true,
            indexed: true
        )
    }

    public static func shortcut() -> ShortcutBlueprint {
        ShortcutBlueprint(
            intentName: intentName,
            phraseTemplates: [
                "Share a summary with {applicationName}",
            ],
            shortTitle: "Share summary",
            systemImageName: "square.and.arrow.up"
        )
    }

    public static func summary(of note: NoteRecord, limit: Int) -> String {
        let collapsed = note.body
            .split(whereSeparator: { $0.isWhitespace })
            .joined(separator: " ")
        let cap = max(1, limit)
        guard collapsed.count > cap else { return collapsed }
        let end = collapsed.index(collapsed.startIndex, offsetBy: cap)
        let head = collapsed[..<end]
        if let space = head.lastIndex(of: " "), space > head.startIndex {
            return String(head[..<space]) + "…"
        }
        return String(head) + "…"
    }

    public static func run(_ input: SummarizeAndShareInput) -> SkillRun {
        var steps = [SkillStep(id: "select-note", detail: "Choose the note to summarize.")]
        guard let note = input.note else {
            let prompt = ValuePrompt(parameter: "note", text: "Which note should be summarized?")
            return SkillRun(
                skillName: name,
                steps: steps,
                outcome: .needsValue(prompt),
                dialog: DialogComposer.value(prompt)
            )
        }
        let shortened = summary(of: note, limit: input.summaryLimit)
        steps.append(SkillStep(id: "summarize", detail: shortened))
        guard let destination = input.destination else {
            let prompt = DisambiguationPrompt(
                parameter: "destination",
                text: "Where should the summary of \"\(note.title)\" go?",
                options: ShareDestination.allCases.map { DisambiguationOption(id: $0.rawValue, label: $0.label) }
            )
            steps.append(SkillStep(id: "pick-destination", detail: prompt.text))
            return SkillRun(
                skillName: name,
                steps: steps,
                outcome: .needsDisambiguation(prompt),
                dialog: DialogComposer.disambiguation(prompt)
            )
        }
        guard let confirmed = input.shareConfirmed else {
            let prompt = ConfirmationPrompt(
                parameter: "share",
                text: "Share this summary of \"\(note.title)\" to \(destination.label)? \(shortened)",
                confirmLabel: "Share",
                denyLabel: "Don't share"
            )
            steps.append(SkillStep(id: "confirm-share", detail: "Ask before calling \(intentName)."))
            return SkillRun(
                skillName: name,
                steps: steps,
                outcome: .needsConfirmation(prompt),
                dialog: DialogComposer.confirmation(prompt)
            )
        }
        if confirmed == .denied {
            steps.append(SkillStep(id: "discard", detail: "The person declined. Nothing was shared."))
            let text = "Nothing was shared."
            return SkillRun(
                skillName: name,
                steps: steps,
                outcome: .cancelled(text),
                dialog: DialogComposer.cancelled(text)
            )
        }
        steps.append(SkillStep(id: "share", detail: "Call \(intentName) for \(destination.label)."))
        let text = "Shared a summary of \"\(note.title)\" to \(destination.label)."
        return SkillRun(
            skillName: name,
            steps: steps,
            outcome: .completed(text),
            dialog: DialogComposer.success(text)
        )
    }
}
