import Foundation

#if canImport(CoreSpotlight) && canImport(AppIntents)
import AppIntents
import CoreSpotlight
import UniformTypeIdentifiers

public enum SkillstrandSpotlightAvailability {
    public static let appleFrameworksLinked = true
}

/// Bridges ``IndexSyncPlan`` and ``SearchItemDraft`` onto a named `CSSearchableIndex`.
///
/// Use a named index. Apple's Spotlight guide reserves the default index for prototypes.
/// `indexAppEntities(_:priority:)` updates an identifier that is already present,
/// so inserts and updates share that call. Deletes use `deleteAppEntities(identifiedBy:ofType:)`.
@available(iOS 18.0, macOS 15.0, *)
public struct EntitySpotlightBridge: Sendable {
    public static let libraryIndexName = "SkillstrandLibrary"

    public var indexName: String
    public var batchSize: Int

    public init(indexName: String, batchSize: Int = SpotlightBatchPlanner.defaultBatchSize) {
        self.indexName = indexName
        self.batchSize = batchSize
    }

    public func index<Entity: IndexedEntity>(_ entities: [Entity], priority: Int = 0) async throws {
        let index = CSSearchableIndex(name: indexName)
        for chunk in IndexSyncCoordinator.chunks(entities, size: batchSize) {
            try await index.indexAppEntities(chunk, priority: priority)
        }
    }

    public func delete<Entity: IndexedEntity>(identifiedBy identifiers: [Entity.ID], type: Entity.Type) async throws {
        let index = CSSearchableIndex(name: indexName)
        for chunk in IndexSyncCoordinator.chunks(identifiers, size: batchSize) {
            try await index.deleteAppEntities(identifiedBy: chunk, ofType: type)
        }
    }

    public func deleteAll<Entity: IndexedEntity>(_ type: Entity.Type) async throws {
        try await CSSearchableIndex(name: indexName).deleteAppEntities(ofType: type)
    }

    public func apply<Entity: IndexedEntity>(
        plan: IndexSyncPlan,
        entities: [Entity],
        type: Entity.Type
    ) async throws where Entity.ID == String {
        let wanted = Set(plan.writes)
        let writing = entities.filter { wanted.contains($0.id) }
        if !writing.isEmpty {
            try await index(writing)
        }
        if !plan.delete.isEmpty {
            try await delete(identifiedBy: plan.delete, type: type)
        }
    }

    public func indexItems(_ drafts: [SearchItemDraft]) async throws {
        let index = CSSearchableIndex(name: indexName)
        for chunk in IndexSyncCoordinator.chunks(drafts, size: batchSize) {
            try await index.indexSearchableItems(chunk.map(Self.makeItem))
        }
    }

    public func deleteItems(identifiers: [String]) async throws {
        let index = CSSearchableIndex(name: indexName)
        for chunk in IndexSyncCoordinator.chunks(identifiers, size: batchSize) {
            try await index.deleteSearchableItems(withIdentifiers: chunk)
        }
    }

    public static func makeItem(_ draft: SearchItemDraft) -> CSSearchableItem {
        let attributes = CSSearchableItemAttributeSet(contentType: .content)
        attributes.title = draft.title
        attributes.contentDescription = draft.contentDescription
        attributes.keywords = draft.keywords
        return CSSearchableItem(
            uniqueIdentifier: draft.uniqueIdentifier,
            domainIdentifier: draft.domainIdentifier,
            attributeSet: attributes
        )
    }
}

#else

public enum SkillstrandSpotlightAvailability {
    public static let appleFrameworksLinked = false
}

#endif
