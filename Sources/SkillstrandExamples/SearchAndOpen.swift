import Foundation
import SkillstrandCore
import SkillstrandEntities
import SkillstrandIntents
import SkillstrandShortcuts

public struct LibraryItem: Sendable, Equatable, Identifiable, Hashable {
    public var id: String
    public var title: String
    public var summary: String

    public init(id: String, title: String, summary: String) {
        self.id = id
        self.title = title
        self.summary = summary
    }

    public var fingerprint: String { "\(title)\n\(summary)" }
}

public struct SearchAndOpenInput: Sendable, Equatable {
    public var query: String
    public var catalog: [LibraryItem]
    public var chosenIdentifier: String?

    public init(query: String, catalog: [LibraryItem], chosenIdentifier: String? = nil) {
        self.query = query
        self.catalog = catalog
        self.chosenIdentifier = chosenIdentifier
    }
}

/// Find one library item and open it, asking for a choice when several titles match.
public enum SearchAndOpenSkill {
    public static let name = "search-and-open"
    public static let intentName = "OpenLibraryItem"

    public static let starterCatalog: [LibraryItem] = [
        LibraryItem(id: "field-notes", title: "Field notes", summary: "Plot marks from the north fence."),
        LibraryItem(id: "field-guide", title: "Field guide", summary: "Grasses and the weeks they seed."),
        LibraryItem(id: "packing", title: "Packing list", summary: "Twine, tags, and a spare pencil."),
        LibraryItem(id: "kiln", title: "Kiln log", summary: "Last firing, cone 6, even heat."),
    ]

    public static func blueprint() -> IntentBlueprint {
        IntentBlueprint(
            name: intentName,
            title: "Open Library Item",
            summary: "Opens a library item that is already in the app."
        ) {
            ParameterSpec(
                name: "item",
                title: "Item",
                summary: "The item to open, found by its string query.",
                type: .entity,
                entityType: "LibraryItem"
            )
        }
    }

    public static func entityBlueprint() -> EntityBlueprint {
        EntityBlueprint(
            typeName: "LibraryItem",
            displayName: "Library item",
            identifierComment: "Stable id. Spotlight and the open tool both use it.",
            properties: [
                PropertyConvention(
                    name: "title",
                    title: "Title",
                    summary: "The name a person would say.",
                    spotlightKey: .title,
                    searchable: true
                ),
                PropertyConvention(
                    name: "summary",
                    title: "Summary",
                    summary: "A short description stored with the item.",
                    spotlightKey: .contentDescription,
                    searchable: true
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
                "Open {applicationName}",
                "Find something in {applicationName}",
            ],
            shortTitle: "Open item",
            systemImageName: "magnifyingglass"
        )
    }

    public static func matches(query: String, catalog: [LibraryItem]) -> [LibraryItem] {
        EntityQueryScaffold(entities: catalog).matching(query) { $0.title }
    }

    public static func run(_ input: SearchAndOpenInput) -> SkillRun {
        var steps = [SkillStep(id: "search", detail: "Run the string query for \"\(input.query)\".")]
        let query = input.query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else {
            return SkillErrorMapping.failed(
                SkillFailure(code: .emptyInput, message: "Say the name of the item to open."),
                skillName: name,
                steps: steps
            )
        }
        let hits = matches(query: query, catalog: input.catalog)
        guard !hits.isEmpty else {
            steps.append(SkillStep(id: "none", detail: "The query matched nothing."))
            return SkillErrorMapping.failed(
                SkillFailure(code: .notFound, message: "Nothing in the library is named \"\(query)\"."),
                skillName: name,
                steps: steps
            )
        }
        let chosen: LibraryItem
        if hits.count == 1 {
            chosen = hits[0]
            steps.append(SkillStep(id: "single-hit", detail: "One match: \(chosen.title)."))
        } else if let identifier = input.chosenIdentifier {
            guard let match = hits.first(where: { $0.id == identifier }) else {
                steps.append(SkillStep(id: "reject-choice", detail: "The choice is not one of the matches."))
                return SkillErrorMapping.failed(
                    SkillFailure(code: .notFound, message: "That choice is not one of the matches."),
                    skillName: name,
                    steps: steps
                )
            }
            chosen = match
            steps.append(SkillStep(id: "chosen", detail: "The person chose \(chosen.title)."))
        } else {
            let prompt = DisambiguationPrompt(
                parameter: "item",
                text: "Which \(query) should be opened?",
                options: hits.map { DisambiguationOption(id: $0.id, label: $0.title) }
            )
            steps.append(SkillStep(id: "disambiguate", detail: prompt.text))
            return SkillRun(
                skillName: name,
                steps: steps,
                outcome: .needsDisambiguation(prompt),
                dialog: DialogComposer.disambiguation(prompt)
            )
        }
        steps.append(SkillStep(id: "open", detail: "Call \(intentName) for \(chosen.id)."))
        let text = "Opened \(chosen.title)."
        return SkillRun(
            skillName: name,
            steps: steps,
            outcome: .completed(text),
            dialog: DialogComposer.success(text)
        )
    }
}

public actor SampleLibrary {
    public static let shared = SampleLibrary()
    public private(set) var items: [LibraryItem]

    public init(items: [LibraryItem] = SearchAndOpenSkill.starterCatalog) {
        self.items = items
    }

    public func replace(with items: [LibraryItem]) {
        self.items = items
    }

    public func search(_ query: String) -> [LibraryItem] {
        SearchAndOpenSkill.matches(query: query, catalog: items)
    }
}
