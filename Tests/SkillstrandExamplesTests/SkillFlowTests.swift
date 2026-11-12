import XCTest
@testable import SkillstrandCore
@testable import SkillstrandEntities
@testable import SkillstrandExamples
@testable import SkillstrandIntents
@testable import SkillstrandShortcuts
@testable import SkillstrandSpotlight

final class CaptureToTaskTests: XCTestCase {
    func testEmptyCaptureAsksForATitle() {
        let run = CaptureToTaskSkill.run(CaptureInput(capture: "  \n"))
        guard case .failed(let failure) = run.outcome else {
            return XCTFail("expected failure, got \(run.outcome)")
        }
        XCTAssertEqual(failure.code, .emptyInput)
        XCTAssertEqual(run.dialog, SkillErrorMapping.dialog(for: failure))
        XCTAssertEqual(run.steps.map(\.id), ["read-capture"])
    }

    func testConfirmationComesBeforeTheFollowUp() {
        let draft = try? XCTUnwrap(CaptureToTaskSkill.draft(from: "Buy twine\nfrom the market"))
        XCTAssertEqual(draft?.title, "Buy twine")
        XCTAssertEqual(draft?.notes, "from the market")

        let pending = CaptureToTaskSkill.run(CaptureInput(capture: "Buy twine\nfrom the market"))
        guard case .needsConfirmation(let prompt) = pending.outcome else {
            return XCTFail("expected confirmation")
        }
        XCTAssertEqual(prompt.parameter, "create")
        XCTAssertEqual(prompt.confirmLabel, "Create")

        let declined = CaptureToTaskSkill.run(
            CaptureInput(capture: "Buy twine", createConfirmed: .denied)
        )
        guard case .cancelled = declined.outcome else {
            return XCTFail("expected cancel")
        }
        XCTAssertTrue(declined.dialog.text.contains("Nothing was saved"))

        let followUp = CaptureToTaskSkill.run(
            CaptureInput(capture: "Buy twine", createConfirmed: .confirmed)
        )
        guard case .needsConfirmation(let due) = followUp.outcome else {
            return XCTFail("expected the due-date follow-up")
        }
        XCTAssertEqual(due.parameter, "due")
        XCTAssertTrue(followUp.steps.map(\.id).contains("create-task"))
    }

    func testDueDateFollowUpOrSkip() {
        let skipped = CaptureToTaskSkill.run(
            CaptureInput(capture: "Buy twine", createConfirmed: .confirmed, followUp: .skip)
        )
        guard case .completed(let message) = skipped.outcome else {
            return XCTFail("expected completion")
        }
        XCTAssertTrue(message.contains("Buy twine"))
        XCTAssertFalse(message.contains("due"))

        let blank = CaptureToTaskSkill.run(
            CaptureInput(capture: "Buy twine", createConfirmed: .confirmed, followUp: .due("  "))
        )
        guard case .failed(let failure) = blank.outcome else {
            return XCTFail("expected a missing date")
        }
        XCTAssertEqual(failure.code, .emptyInput)

        let dated = CaptureToTaskSkill.run(
            CaptureInput(capture: "Buy twine", createConfirmed: .confirmed, followUp: .due("Friday at 9:00"))
        )
        guard case .completed(let datedMessage) = dated.outcome else {
            return XCTFail("expected a dated task")
        }
        XCTAssertTrue(datedMessage.contains("Friday at 9:00"))
        XCTAssertEqual(dated.steps.last?.id, "set-due")
    }
}

final class SearchAndOpenTests: XCTestCase {
    func testZeroOneAndManyMatches() {
        let catalog = SearchAndOpenSkill.starterCatalog
        let empty = SearchAndOpenSkill.run(SearchAndOpenInput(query: "   ", catalog: catalog))
        guard case .failed(let emptyFailure) = empty.outcome else { return XCTFail() }
        XCTAssertEqual(emptyFailure.code, .emptyInput)

        let none = SearchAndOpenSkill.run(SearchAndOpenInput(query: "obsidian", catalog: catalog))
        guard case .failed(let noneFailure) = none.outcome else { return XCTFail() }
        XCTAssertEqual(noneFailure.code, .notFound)

        let one = SearchAndOpenSkill.run(SearchAndOpenInput(query: "kiln", catalog: catalog))
        guard case .completed(let opened) = one.outcome else { return XCTFail("\(one.outcome)") }
        XCTAssertTrue(opened.contains("Kiln log"))
        XCTAssertEqual(one.steps.map(\.id), ["search", "single-hit", "open"])

        let many = SearchAndOpenSkill.run(SearchAndOpenInput(query: "field", catalog: catalog))
        guard case .needsDisambiguation(let prompt) = many.outcome else { return XCTFail() }
        XCTAssertEqual(prompt.options.map(\.id), ["field-notes", "field-guide"])

        let chosen = SearchAndOpenSkill.run(
            SearchAndOpenInput(query: "field", catalog: catalog, chosenIdentifier: "field-guide")
        )
        guard case .completed(let choice) = chosen.outcome else { return XCTFail() }
        XCTAssertTrue(choice.contains("Field guide"))

        let rejected = SearchAndOpenSkill.run(
            SearchAndOpenInput(query: "field", catalog: catalog, chosenIdentifier: "kiln")
        )
        guard case .failed(let rejectedFailure) = rejected.outcome else { return XCTFail() }
        XCTAssertEqual(rejectedFailure.code, .notFound)
    }
}

final class SummarizeAndShareTests: XCTestCase {
    func testSummaryCutsOnAWordAndTheShareFlowConfirms() {
        let note = SummarizeAndShareSkill.starterNotes[0]
        let shortened = SummarizeAndShareSkill.summary(of: note, limit: 40)
        XCTAssertTrue(shortened.hasSuffix("…"))
        XCTAssertFalse(shortened.dropLast().hasSuffix(" "))
        XCTAssertLessThan(shortened.dropLast().count, 40)
        XCTAssertLessThan(shortened.count, note.body.count)

        let missing = SummarizeAndShareSkill.run(SummarizeAndShareInput())
        guard case .needsValue(let value) = missing.outcome else { return XCTFail() }
        XCTAssertEqual(value.parameter, "note")

        let pick = SummarizeAndShareSkill.run(SummarizeAndShareInput(note: note))
        guard case .needsDisambiguation(let destinations) = pick.outcome else { return XCTFail() }
        XCTAssertEqual(destinations.options.map(\.id), ["messages", "mail", "copy"])

        let confirm = SummarizeAndShareSkill.run(
            SummarizeAndShareInput(note: note, destination: .mail)
        )
        guard case .needsConfirmation(let prompt) = confirm.outcome else { return XCTFail() }
        XCTAssertTrue(prompt.text.contains("Mail"))
        XCTAssertTrue(prompt.text.contains(SummarizeAndShareSkill.summary(of: note, limit: 180)))

        let declined = SummarizeAndShareSkill.run(
            SummarizeAndShareInput(note: note, destination: .copy, shareConfirmed: .denied)
        )
        guard case .cancelled = declined.outcome else { return XCTFail() }

        let shared = SummarizeAndShareSkill.run(
            SummarizeAndShareInput(note: note, destination: .messages, shareConfirmed: .confirmed)
        )
        guard case .completed(let message) = shared.outcome else { return XCTFail() }
        XCTAssertTrue(message.contains("Messages"))
        XCTAssertEqual(shared.dialog.kind, .success)
    }
}

final class ScheduledReminderTests: XCTestCase {
    func testDisambiguationThenConfirmation() {
        let missing = ScheduledReminderSkill.run(
            ScheduledReminderInput(title: "  ", choices: ScheduledReminderSkill.fridayChoices)
        )
        guard case .failed(let failure) = missing.outcome else { return XCTFail() }
        XCTAssertEqual(failure.code, .emptyInput)

        let noTime = ScheduledReminderSkill.run(ScheduledReminderInput(title: "Call the yard", choices: []))
        guard case .failed(let timeFailure) = noTime.outcome else { return XCTFail() }
        XCTAssertEqual(timeFailure.code, .notFound)

        let ambiguous = ScheduledReminderSkill.run(
            ScheduledReminderInput(title: "Call the yard", choices: ScheduledReminderSkill.fridayChoices)
        )
        guard case .needsDisambiguation(let prompt) = ambiguous.outcome else { return XCTFail() }
        XCTAssertEqual(prompt.options.map(\.label), ["Friday at 9:00", "Friday at 6:00"])

        let confirm = ScheduledReminderSkill.run(
            ScheduledReminderInput(
                title: "Call the yard",
                choices: ScheduledReminderSkill.fridayChoices,
                chosenIdentifier: "fri-am"
            )
        )
        guard case .needsConfirmation(let confirmation) = confirm.outcome else { return XCTFail() }
        XCTAssertTrue(confirmation.text.contains("Friday at 9:00"))

        let declined = ScheduledReminderSkill.run(
            ScheduledReminderInput(
                title: "Call the yard",
                choices: ScheduledReminderSkill.fridayChoices,
                chosenIdentifier: "fri-am",
                confirmed: .denied
            )
        )
        guard case .cancelled = declined.outcome else { return XCTFail() }

        let scheduled = ScheduledReminderSkill.run(
            ScheduledReminderInput(
                title: "Call the yard",
                choices: ScheduledReminderSkill.fridayChoices,
                chosenIdentifier: "fri-pm",
                confirmed: .confirmed
            )
        )
        guard case .completed(let message) = scheduled.outcome else { return XCTFail() }
        XCTAssertTrue(message.contains("Friday at 6:00"))
    }
}

final class IndexAndShortcutTests: XCTestCase {
    func testSyncPlanBatchesAndSession() async {
        let indexed = [
            IndexedRecord(identifier: "a", fingerprint: "1"),
            IndexedRecord(identifier: "b", fingerprint: "1"),
        ]
        let current = [
            IndexedRecord(identifier: "b", fingerprint: "2"),
            IndexedRecord(identifier: "c", fingerprint: "1"),
        ]
        let plan = IndexSyncCoordinator.plan(indexed: indexed, current: current)
        XCTAssertEqual(plan.insert, ["c"])
        XCTAssertEqual(plan.update, ["b"])
        XCTAssertEqual(plan.delete, ["a"])
        XCTAssertTrue(plan.unchanged.isEmpty)

        let mutations = SpotlightBatchPlanner.mutations(from: plan, batchSize: 1)
        XCTAssertEqual(mutations.map(\.action), [.index, .update, .delete])
        XCTAssertEqual(IndexSyncCoordinator.chunks([1, 2, 3, 4], size: 3).count, 2)

        let session = IndexSyncSession(store: MemoryIndexStore())
        let first = await session.plan(typeName: "LibraryItem", current: current)
        XCTAssertEqual(first.insert, ["b", "c"])
        await session.accept(typeName: "LibraryItem", current: current)
        let second = await session.plan(typeName: "LibraryItem", current: current)
        XCTAssertEqual(second.unchanged, ["b", "c"])
        XCTAssertTrue(second.insert.isEmpty)
        XCTAssertTrue(second.delete.isEmpty)
    }

    func testShortcutPhrasesRequireTheApplicationName() throws {
        for skill in ExampleSkillCatalog.all {
            XCTAssertNoThrow(try skill.shortcut.validate())
            XCTAssertTrue(skill.intent.toolEligible)
            XCTAssertFalse(skill.intent.parameters.isEmpty)
        }
        var broken = SearchAndOpenSkill.shortcut()
        broken.phraseTemplates = ["Open the library"]
        XCTAssertThrowsError(try broken.validate()) { error in
            XCTAssertEqual(error as? ShortcutBlueprintError, .missingApplicationName("Open the library"))
        }
        let source = try AppShortcutsSource.render(
            typeName: "SampleShortcuts",
            blueprints: ExampleSkillCatalog.all.map(\.shortcut)
        )
        XCTAssertTrue(source.contains("\\(.applicationName)"))
        XCTAssertTrue(source.contains("struct SampleShortcuts: AppShortcutsProvider"))
        XCTAssertTrue(source.contains("CreateTask()"))
    }

    func testErrorMappingIsStable() {
        let failure = SkillFailure(code: .notFound, message: "No time matched that phrase.")
        let dialog = SkillErrorMapping.dialog(for: failure)
        XCTAssertEqual(dialog.text, "Nothing matched: No time matched that phrase.")
        XCTAssertEqual(dialog.kind, .failure)
        let scaffold = EntityQueryScaffold(entities: SearchAndOpenSkill.starterCatalog)
        XCTAssertEqual(scaffold.entities(for: ["kiln", "missing"]).map(\.id), ["kiln"])
        XCTAssertEqual(scaffold.suggested(limit: 1).map(\.id), ["field-notes"])
    }
}

final class BundledSkillTests: XCTestCase {
    func testExampleBundleAndSampleApp() throws {
        let documents = try ExampleSkillCatalog.bundledDocuments()
        XCTAssertEqual(
            documents.map(\.name),
            ["capture-to-task", "scheduled-reminder", "search-and-open", "summarize-and-share"]
        )
        let byName = Dictionary(uniqueKeysWithValues: documents.map { ($0.name, $0) })
        for skill in ExampleSkillCatalog.all {
            let document = try XCTUnwrap(byName[skill.name])
            XCTAssertTrue(document.body.contains(skill.intent.name))
            XCTAssertLessThanOrEqual(document.summary.count, SkillDocumentParser.maximumDescriptionLength)
        }

        let repo = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let sample = try SkillBundleValidator.load(
            at: repo.appendingPathComponent("Examples/SampleApp/Skills.skillsbundle")
        )
        XCTAssertEqual(sample, documents)
    }
}
