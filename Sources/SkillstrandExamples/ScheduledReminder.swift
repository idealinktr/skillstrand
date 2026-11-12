import Foundation
import SkillstrandCore
import SkillstrandIntents
import SkillstrandShortcuts

public struct WhenChoice: Sendable, Equatable, Identifiable, Hashable {
    public var id: String
    public var label: String

    public init(id: String, label: String) {
        self.id = id
        self.label = label
    }
}

public struct ScheduledReminderInput: Sendable, Equatable {
    public var title: String
    public var choices: [WhenChoice]
    public var chosenIdentifier: String?
    public var confirmed: ConfirmationAnswer?

    public init(
        title: String,
        choices: [WhenChoice],
        chosenIdentifier: String? = nil,
        confirmed: ConfirmationAnswer? = nil
    ) {
        self.title = title
        self.choices = choices
        self.chosenIdentifier = chosenIdentifier
        self.confirmed = confirmed
    }
}

/// Schedule a reminder once a vague time has been narrowed to one choice and confirmed.
public enum ScheduledReminderSkill {
    public static let name = "scheduled-reminder"
    public static let intentName = "ScheduleReminder"

    public static let fridayChoices: [WhenChoice] = [
        WhenChoice(id: "fri-am", label: "Friday at 9:00"),
        WhenChoice(id: "fri-pm", label: "Friday at 6:00"),
    ]

    public static func blueprint() -> IntentBlueprint {
        IntentBlueprint(
            name: intentName,
            title: "Schedule Reminder",
            summary: "Schedules a reminder after the person picks one time and confirms it."
        ) {
            ParameterSpec(
                name: "title",
                title: "Title",
                summary: "What the reminder is for.",
                type: .string
            )
            ParameterSpec(
                name: "when",
                title: "When",
                summary: "The single time the person picked.",
                type: .string
            )
        }
    }

    public static func shortcut() -> ShortcutBlueprint {
        ShortcutBlueprint(
            intentName: intentName,
            phraseTemplates: [
                "Set a reminder in {applicationName}",
            ],
            shortTitle: "Set reminder",
            systemImageName: "bell"
        )
    }

    public static func run(_ input: ScheduledReminderInput) -> SkillRun {
        var steps = [SkillStep(id: "read-title", detail: "Read the reminder title.")]
        let title = input.title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else {
            return SkillErrorMapping.failed(
                SkillFailure(code: .emptyInput, message: "Say what the reminder is for."),
                skillName: name,
                steps: steps
            )
        }
        guard !input.choices.isEmpty else {
            steps.append(SkillStep(id: "no-time", detail: "The time phrase matched no concrete moment."))
            return SkillErrorMapping.failed(
                SkillFailure(code: .notFound, message: "No time matched that phrase."),
                skillName: name,
                steps: steps
            )
        }
        let chosen: WhenChoice
        if input.choices.count == 1 {
            chosen = input.choices[0]
            steps.append(SkillStep(id: "single-time", detail: chosen.label))
        } else if let identifier = input.chosenIdentifier {
            guard let match = input.choices.first(where: { $0.id == identifier }) else {
                steps.append(SkillStep(id: "reject-time", detail: "The choice is not one of the times."))
                return SkillErrorMapping.failed(
                    SkillFailure(code: .notFound, message: "That time is not one of the choices."),
                    skillName: name,
                    steps: steps
                )
            }
            chosen = match
            steps.append(SkillStep(id: "chosen-time", detail: chosen.label))
        } else {
            let prompt = DisambiguationPrompt(
                parameter: "when",
                text: "Which time should \"\(title)\" use?",
                options: input.choices.map { DisambiguationOption(id: $0.id, label: $0.label) }
            )
            steps.append(SkillStep(id: "disambiguate-when", detail: prompt.text))
            return SkillRun(
                skillName: name,
                steps: steps,
                outcome: .needsDisambiguation(prompt),
                dialog: DialogComposer.disambiguation(prompt)
            )
        }
        guard let confirmed = input.confirmed else {
            let prompt = ConfirmationPrompt(
                parameter: "schedule",
                text: "Schedule \"\(title)\" for \(chosen.label)?",
                confirmLabel: "Schedule",
                denyLabel: "Cancel"
            )
            steps.append(SkillStep(id: "confirm-schedule", detail: prompt.text))
            return SkillRun(
                skillName: name,
                steps: steps,
                outcome: .needsConfirmation(prompt),
                dialog: DialogComposer.confirmation(prompt)
            )
        }
        if confirmed == .denied {
            steps.append(SkillStep(id: "discard", detail: "The person declined. Nothing was scheduled."))
            let text = "Nothing was scheduled."
            return SkillRun(
                skillName: name,
                steps: steps,
                outcome: .cancelled(text),
                dialog: DialogComposer.cancelled(text)
            )
        }
        steps.append(SkillStep(id: "schedule", detail: "Call \(intentName)."))
        let text = "Scheduled \"\(title)\" for \(chosen.label)."
        return SkillRun(
            skillName: name,
            steps: steps,
            outcome: .completed(text),
            dialog: DialogComposer.success(text)
        )
    }
}
