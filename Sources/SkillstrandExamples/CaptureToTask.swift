import Foundation
import SkillstrandCore
import SkillstrandEntities
import SkillstrandIntents
import SkillstrandShortcuts

public enum CaptureFollowUp: Sendable, Equatable {
    case skip
    case due(String)
}

public struct CaptureInput: Sendable, Equatable {
    public var capture: String
    public var createConfirmed: ConfirmationAnswer?
    public var followUp: CaptureFollowUp?

    public init(
        capture: String,
        createConfirmed: ConfirmationAnswer? = nil,
        followUp: CaptureFollowUp? = nil
    ) {
        self.capture = capture
        self.createConfirmed = createConfirmed
        self.followUp = followUp
    }
}

public struct TaskDraft: Sendable, Equatable {
    public var title: String
    public var notes: String

    public init(title: String, notes: String) {
        self.title = title
        self.notes = notes
    }
}

/// Capture text, confirm the title, then ask whether to add a due date.
public enum CaptureToTaskSkill {
    public static let name = "capture-to-task"
    public static let intentName = "CreateTask"
    public static let followUpIntentName = "SetTaskDue"

    public static func draft(from capture: String) -> TaskDraft? {
        let lines = capture
            .replacingOccurrences(of: "\r\n", with: "\n")
            .split(separator: "\n", omittingEmptySubsequences: false)
            .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
        guard let first = lines.first(where: { !$0.isEmpty }) else { return nil }
        let title = String(first.prefix(80))
        let notes = lines.drop { $0.isEmpty || $0 == first }.joined(separator: "\n")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return TaskDraft(title: title, notes: notes)
    }

    public static func blueprint() -> IntentBlueprint {
        IntentBlueprint(
            name: intentName,
            title: "Create Task",
            summary: "Creates a task from a title the person has confirmed."
        ) {
            ParameterSpec(
                name: "title",
                title: "Title",
                summary: "The task title taken from the first line of the capture.",
                type: .string
            )
            ParameterSpec(
                name: "notes",
                title: "Notes",
                summary: "The remaining capture text.",
                type: .string,
                required: false
            )
        }
    }

    public static func shortcut() -> ShortcutBlueprint {
        ShortcutBlueprint(
            intentName: intentName,
            phraseTemplates: [
                "Capture a task with {applicationName}",
                "Save a to-do in {applicationName}",
            ],
            shortTitle: "Capture task",
            systemImageName: "checkmark.circle"
        )
    }

    public static func run(_ input: CaptureInput) -> SkillRun {
        var steps = [SkillStep(id: "read-capture", detail: "Read the capture and take the title from the first line.")]
        guard let draft = draft(from: input.capture) else {
            return SkillErrorMapping.failed(
                SkillFailure(code: .emptyInput, message: "Say a title before creating a task."),
                skillName: name,
                steps: steps
            )
        }
        guard let confirmed = input.createConfirmed else {
            let prompt = ConfirmationPrompt(
                parameter: "create",
                text: "Create the task \"\(draft.title)\"?",
                confirmLabel: "Create",
                denyLabel: "Cancel"
            )
            steps.append(SkillStep(id: "confirm-create", detail: prompt.text))
            return SkillRun(
                skillName: name,
                steps: steps,
                outcome: .needsConfirmation(prompt),
                dialog: DialogComposer.confirmation(prompt)
            )
        }
        if confirmed == .denied {
            steps.append(SkillStep(id: "discard", detail: "The person declined. Nothing was saved."))
            let text = "Nothing was saved."
            return SkillRun(
                skillName: name,
                steps: steps,
                outcome: .cancelled(text),
                dialog: DialogComposer.cancelled(text)
            )
        }
        steps.append(SkillStep(id: "create-task", detail: "Call \(intentName) for \"\(draft.title)\"."))
        guard let followUp = input.followUp else {
            let prompt = ConfirmationPrompt(
                parameter: "due",
                text: "Saved \"\(draft.title)\". Add a due date?",
                confirmLabel: "Add a date",
                denyLabel: "Not now"
            )
            steps.append(SkillStep(id: "confirm-follow-up", detail: prompt.text))
            return SkillRun(
                skillName: name,
                steps: steps,
                outcome: .needsConfirmation(prompt),
                dialog: DialogComposer.confirmation(prompt)
            )
        }
        switch followUp {
        case .skip:
            steps.append(SkillStep(id: "skip-due", detail: "Leave the due date unset."))
            let text = "Created the task \"\(draft.title)\"."
            return SkillRun(
                skillName: name,
                steps: steps,
                outcome: .completed(text),
                dialog: DialogComposer.success(text)
            )
        case .due(let raw):
            let due = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !due.isEmpty else {
                steps.append(SkillStep(id: "read-due", detail: "The due date was blank."))
                return SkillErrorMapping.failed(
                    SkillFailure(code: .emptyInput, message: "Say when the task is due, or skip the date."),
                    skillName: name,
                    steps: steps
                )
            }
            steps.append(SkillStep(id: "set-due", detail: "Call \(followUpIntentName) with \(due)."))
            let text = "Created the task \"\(draft.title)\", due \(due)."
            return SkillRun(
                skillName: name,
                steps: steps,
                outcome: .completed(text),
                dialog: DialogComposer.success(text)
            )
        }
    }
}
