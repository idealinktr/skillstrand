import Foundation

#if canImport(AppIntents) && canImport(CoreSpotlight)
import AppIntents
import CoreSpotlight
import SkillstrandCore
import SkillstrandEntities
import SkillstrandIntents
import SkillstrandSpotlight
import UniformTypeIdentifiers

public enum SkillstrandExamplesAvailability {
    public static let appleFrameworksLinked = true
}

@available(iOS 18.0, macOS 15.0, *)
public struct LibraryItemEntity: IndexedEntity, Sendable {
    public static let typeDisplayRepresentation = TypeDisplayRepresentation(name: "Library item")
    public static let defaultQuery = LibraryItemQuery()

    public var id: String
    public var title: String
    public var summary: String

    /// Spotlight reads a computed field through `@ComputedProperty`. That macro
    /// shipped with the iOS 26 SDK (Swift 6.2). Xcode 16 only has `attributeSet`,
    /// which still carries the summary, so the macro stays off older compilers.
    #if compiler(>=6.2)
    @ComputedProperty(indexingKey: \.contentDescription)
    public var contentDescription: String { summary }
    #endif

    public var displayRepresentation: DisplayRepresentation {
        EntityDisplayMapping.representation(title: title, subtitle: summary)
    }

    public var attributeSet: CSSearchableItemAttributeSet {
        let attributes = CSSearchableItemAttributeSet(contentType: .content)
        attributes.title = title
        attributes.contentDescription = summary
        return attributes
    }

    public init(id: String, title: String, summary: String) {
        self.id = id
        self.title = title
        self.summary = summary
    }

    public init(_ item: LibraryItem) {
        self.init(id: item.id, title: item.title, summary: item.summary)
    }
}

@available(iOS 18.0, macOS 15.0, *)
public struct LibraryItemQuery: EntityStringQuery {
    public init() {}

    public func entities(for identifiers: [LibraryItemEntity.ID]) async throws -> [LibraryItemEntity] {
        let items = await SampleLibrary.shared.items
        return items.filter { identifiers.contains($0.id) }.map(LibraryItemEntity.init)
    }

    public func entities(matching string: String) async throws -> [LibraryItemEntity] {
        let items = await SampleLibrary.shared.search(string)
        return items.map(LibraryItemEntity.init)
    }

    public func suggestedEntities() async throws -> [LibraryItemEntity] {
        await SampleLibrary.shared.items.map(LibraryItemEntity.init)
    }
}

/// `IndexedEntityQuery` and `CSSearchableIndexDescription` arrived in the iOS 27 SDK.
/// Xcode 27.3 beta ships Swift 6.4. `#available` cannot hide a missing protocol,
/// same as `@AppIntent(.tool)`.
#if compiler(>=6.4)
@available(iOS 27.0, macOS 27.0, *)
extension LibraryItemQuery: IndexedEntityQuery {
    /// `indexDescription` tells the app which named index to refresh. The sample keeps one name.
    public func reindexEntities(
        for identifiers: [LibraryItemEntity.ID],
        indexDescription: CSSearchableIndexDescription
    ) async throws {
        _ = indexDescription
        let entities = try await entities(for: identifiers)
        try await EntitySpotlightBridge(indexName: EntitySpotlightBridge.libraryIndexName).index(entities)
    }

    public func reindexAllEntities(indexDescription: CSSearchableIndexDescription) async throws {
        _ = indexDescription
        let entities = try await suggestedEntities()
        try await EntitySpotlightBridge(indexName: EntitySpotlightBridge.libraryIndexName).index(entities)
    }
}
#endif

@available(iOS 18.0, macOS 15.0, *)
public struct CreateTaskIntent: AppIntent, Sendable {
    public static let title: LocalizedStringResource = "Create Task"
    public static let description = IntentDescription("Creates a task from a title the person has confirmed.")
    public static let isDiscoverable = true

    @Parameter(title: "Title", description: "The task title taken from the first line of the capture.")
    public var title: String

    @Parameter(title: "Notes", description: "The remaining capture text.")
    public var notes: String?

    public init() {
        title = ""
        notes = nil
    }

    public init(title: String, notes: String?) {
        self.title = title
        self.notes = notes
    }

    public func perform() async throws -> some IntentResult {
        let capture = notes.map { title + "\n" + $0 } ?? title
        let run = CaptureToTaskSkill.run(
            CaptureInput(capture: capture, createConfirmed: .confirmed, followUp: .skip)
        )
        if case .failed(let failure) = run.outcome {
            throw failure
        }
        return .result(dialog: SkillIntentResults.intentDialog(run.dialog))
    }
}

@available(iOS 18.0, macOS 15.0, *)
public struct OpenLibraryItemIntent: OpenIntent, Sendable {
    public static let title: LocalizedStringResource = "Open Library Item"
    public static let description = IntentDescription("Opens a library item that is already in the app.")

    @Parameter(title: "Item", description: "The item to open, found by its string query.", requestValueDialog: "Which item?")
    public var target: LibraryItemEntity

    public init() {
        target = LibraryItemEntity(id: "", title: "", summary: "")
    }

    public init(target: LibraryItemEntity) {
        self.target = target
    }

    public func perform() async throws -> some IntentResult {
        .result(dialog: IntentDialog("Opened \(target.title)."))
    }
}

@available(iOS 18.0, macOS 15.0, *)
public struct ScheduleReminderIntent: AppIntent, Sendable {
    public static let title: LocalizedStringResource = "Schedule Reminder"
    public static let description = IntentDescription("Schedules a reminder after the person picks one time and confirms it.")
    public static let isDiscoverable = true

    @Parameter(title: "Title", description: "What the reminder is for.")
    public var title: String

    @Parameter(title: "When", description: "The single time the person picked.")
    public var when: String

    public init() {
        title = ""
        when = ""
    }

    public func perform() async throws -> some IntentResult {
        let run = ScheduledReminderSkill.run(
            ScheduledReminderInput(
                title: title,
                choices: [WhenChoice(id: "chosen", label: when)],
                confirmed: .confirmed
            )
        )
        if case .failed(let failure) = run.outcome {
            throw failure
        }
        return .result(dialog: SkillIntentResults.intentDialog(run.dialog))
    }
}

@available(iOS 18.0, macOS 15.0, *)
public struct ShareSummaryIntent: AppIntent, Sendable {
    public static let title: LocalizedStringResource = "Share Summary"
    public static let description = IntentDescription("Shares a short summary after the person picks a destination and confirms.")
    public static let isDiscoverable = true

    @Parameter(title: "Summary", description: "The shortened note that will be shared.")
    public var summary: String

    @Parameter(title: "Destination", description: "Messages, Mail, or Copy.")
    public var destination: String

    public init() {
        summary = ""
        destination = ""
    }

    public func perform() async throws -> some IntentResult {
        guard !summary.isEmpty, !destination.isEmpty else {
            throw SkillFailure(code: .emptyInput, message: "A summary and a destination are required.")
        }
        return .result(dialog: IntentDialog("Shared the summary to \(destination)."))
    }
}

#else

public enum SkillstrandExamplesAvailability {
    public static let appleFrameworksLinked = false
}

#endif
