import Skillstrand
import SwiftUI

struct SkillStudio: View {
    let skill: ExampleSkill

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text(skill.summary)
                    .font(.title3)
                    .foregroundStyle(StrandTheme.ink)
                StrandCard {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(skill.intent.title).font(.headline)
                        Text(skill.intent.summary).foregroundStyle(.secondary)
                        ForEach(skill.intent.parameters, id: \.name) { parameter in
                            Text("\(parameter.title) · \(parameter.type.rawValue)")
                                .font(.callout)
                        }
                        Text(skill.shortcut.phraseTemplates.joined(separator: "\n"))
                            .font(.callout.monospaced())
                            .foregroundStyle(StrandTheme.teal)
                    }
                }
                switch skill.name {
                case CaptureToTaskSkill.name:
                    CaptureStudio()
                case SearchAndOpenSkill.name:
                    SearchStudio()
                case SummarizeAndShareSkill.name:
                    ShareStudio()
                case ScheduledReminderSkill.name:
                    ReminderStudio()
                default:
                    EmptyView()
                }
            }
            .padding(20)
            .frame(maxWidth: 720, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(StrandTheme.paper)
        .navigationTitle(skill.title)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.large)
        #endif
    }
}

private struct RunCard: View {
    let run: SkillRun

    var body: some View {
        StrandCard {
            VStack(alignment: .leading, spacing: 8) {
                Text(run.dialog.text).font(.body.weight(.semibold))
                ForEach(Array(run.steps.enumerated()), id: \.offset) { _, step in
                    Text("\(step.id): \(step.detail)")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

private struct CaptureStudio: View {
    @State private var capture = "Buy twine\nfrom the market stall"
    @State private var confirmed: ConfirmationAnswer?
    @State private var followUp: CaptureFollowUp?
    @State private var due = "Friday at 9:00"
    @State private var run: SkillRun?

    var body: some View {
        StrandCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Capture").font(.headline)
                TextField("First line is the title", text: $capture, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                ChoiceButton(title: "Read the capture", prominent: true) {
                    confirmed = nil
                    followUp = nil
                    refresh()
                }
                if case .needsConfirmation(let prompt) = run?.outcome, prompt.parameter == "create" {
                    ChoiceButton(title: prompt.confirmLabel) {
                        confirmed = .confirmed
                        refresh()
                    }
                    ChoiceButton(title: prompt.denyLabel) {
                        confirmed = .denied
                        refresh()
                    }
                }
                if case .needsConfirmation(let prompt) = run?.outcome, prompt.parameter == "due" {
                    TextField("Due date", text: $due)
                        .textFieldStyle(.roundedBorder)
                    ChoiceButton(title: prompt.confirmLabel) {
                        followUp = .due(due)
                        refresh()
                    }
                    ChoiceButton(title: prompt.denyLabel) {
                        followUp = .skip
                        refresh()
                    }
                }
            }
        }
        if let run { RunCard(run: run) }
    }

    private func refresh() {
        run = CaptureToTaskSkill.run(
            CaptureInput(capture: capture, createConfirmed: confirmed, followUp: followUp)
        )
    }
}

private struct SearchStudio: View {
    @State private var query = "field"
    @State private var choice: String?
    @State private var run: SkillRun?

    var body: some View {
        StrandCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Library").font(.headline)
                TextField("Name to find", text: $query)
                    .textFieldStyle(.roundedBorder)
                ChoiceButton(title: "Search", prominent: true) {
                    choice = nil
                    refresh()
                }
                if case .needsDisambiguation(let prompt) = run?.outcome {
                    ForEach(prompt.options) { option in
                        ChoiceButton(title: option.label) {
                            choice = option.id
                            refresh()
                        }
                    }
                }
            }
        }
        if let run { RunCard(run: run) }
    }

    private func refresh() {
        run = SearchAndOpenSkill.run(
            SearchAndOpenInput(
                query: query,
                catalog: SearchAndOpenSkill.starterCatalog,
                chosenIdentifier: choice
            )
        )
    }
}

private struct ShareStudio: View {
    @State private var note: NoteRecord?
    @State private var destination: ShareDestination?
    @State private var confirmed: ConfirmationAnswer?
    @State private var run: SkillRun?

    var body: some View {
        StrandCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Notes").font(.headline)
                ForEach(SummarizeAndShareSkill.starterNotes) { item in
                    ChoiceButton(title: item.title, prominent: note?.id == item.id) {
                        note = item
                        destination = nil
                        confirmed = nil
                        refresh()
                    }
                }
                if note != nil, destination == nil {
                    ForEach(ShareDestination.allCases) { item in
                        ChoiceButton(title: item.label) {
                            destination = item
                            refresh()
                        }
                    }
                }
                if case .needsConfirmation(let prompt) = run?.outcome {
                    ChoiceButton(title: prompt.confirmLabel, prominent: true) {
                        confirmed = .confirmed
                        refresh()
                    }
                    ChoiceButton(title: prompt.denyLabel) {
                        confirmed = .denied
                        refresh()
                    }
                }
            }
        }
        if let run { RunCard(run: run) }
    }

    private func refresh() {
        run = SummarizeAndShareSkill.run(
            SummarizeAndShareInput(note: note, destination: destination, shareConfirmed: confirmed)
        )
    }
}

private struct ReminderStudio: View {
    @State private var title = "Call the yard"
    @State private var choice: String?
    @State private var confirmed: ConfirmationAnswer?
    @State private var run: SkillRun?

    var body: some View {
        StrandCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Friday").font(.headline)
                TextField("Reminder title", text: $title)
                    .textFieldStyle(.roundedBorder)
                ChoiceButton(title: "Resolve Friday", prominent: true) {
                    choice = nil
                    confirmed = nil
                    refresh()
                }
                if case .needsDisambiguation(let prompt) = run?.outcome {
                    ForEach(prompt.options) { option in
                        ChoiceButton(title: option.label) {
                            choice = option.id
                            refresh()
                        }
                    }
                }
                if case .needsConfirmation(let prompt) = run?.outcome {
                    ChoiceButton(title: prompt.confirmLabel, prominent: true) {
                        confirmed = .confirmed
                        refresh()
                    }
                    ChoiceButton(title: prompt.denyLabel) {
                        confirmed = .denied
                        refresh()
                    }
                }
            }
        }
        if let run { RunCard(run: run) }
    }

    private func refresh() {
        run = ScheduledReminderSkill.run(
            ScheduledReminderInput(
                title: title,
                choices: ScheduledReminderSkill.fridayChoices,
                chosenIdentifier: choice,
                confirmed: confirmed
            )
        )
    }
}
