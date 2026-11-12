import Foundation

/// Property rules shared by an entity, its query, and the Spotlight bridge.
///
/// `internalOnly` is the package's name for the preview visibility that
/// Apple's 27.3 notes call `.internal`. The symbol is not referenced here,
/// because the preview can still move. See `docs/COMPATIBILITY.md`.
public struct PropertyConvention: Sendable, Equatable {
    public enum SpotlightKey: String, Sendable, Equatable {
        case title
        case contentDescription
        case keywords
        case identifier
    }

    public enum Visibility: String, Sendable, Equatable {
        case assistant
        case internalOnly
    }

    public var name: String
    public var title: String
    public var summary: String
    public var spotlightKey: SpotlightKey
    public var searchable: Bool
    public var visibility: Visibility

    public init(
        name: String,
        title: String,
        summary: String,
        spotlightKey: SpotlightKey,
        searchable: Bool,
        visibility: Visibility = .assistant
    ) {
        self.name = name
        self.title = title
        self.summary = summary
        self.spotlightKey = spotlightKey
        self.searchable = searchable
        self.visibility = visibility
    }
}

public struct EntityBlueprint: Sendable, Equatable {
    public var typeName: String
    public var displayName: String
    public var identifierComment: String
    public var properties: [PropertyConvention]
    public var stringQuery: Bool
    public var indexed: Bool
    /// When true, the entity is a candidate for `GenerableEntity` on the 27.3 SDK.
    /// The protocol is not adopted in this module. The requirements are still a preview surface.
    public var generable: Bool

    public init(
        typeName: String,
        displayName: String,
        identifierComment: String,
        properties: [PropertyConvention],
        stringQuery: Bool,
        indexed: Bool,
        generable: Bool = false
    ) {
        self.typeName = typeName
        self.displayName = displayName
        self.identifierComment = identifierComment
        self.properties = properties
        self.stringQuery = stringQuery
        self.indexed = indexed
        self.generable = generable
    }
}

/// In-memory stand-in for `EntityQuery` and `EntityStringQuery`.
///
/// Identifier lookup keeps the caller's identifier order out of the result on
/// purpose: callers match by id. String lookup is a case-insensitive contains
/// over the text you supply, which is the same rule the example skills use.
public struct EntityQueryScaffold<Entity: Identifiable & Sendable>: Sendable where Entity.ID: Hashable & Sendable {
    public var entities: [Entity]

    public init(entities: [Entity]) {
        self.entities = entities
    }

    public func entities(for identifiers: [Entity.ID]) -> [Entity] {
        let wanted = Set(identifiers)
        return entities.filter { wanted.contains($0.id) }
    }

    public func suggested(limit: Int) -> [Entity] {
        Array(entities.prefix(max(0, limit)))
    }

    public func matching(_ query: String, text: (Entity) -> String) -> [Entity] {
        let needle = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !needle.isEmpty else { return [] }
        return entities.filter { text($0).localizedCaseInsensitiveContains(needle) }
    }
}
