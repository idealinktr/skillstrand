import Foundation

public struct IndexedRecord: Sendable, Equatable, Hashable {
    public var identifier: String
    public var fingerprint: String

    public init(identifier: String, fingerprint: String) {
        self.identifier = identifier
        self.fingerprint = fingerprint
    }
}

public struct IndexSyncPlan: Sendable, Equatable {
    public var insert: [String]
    public var update: [String]
    public var delete: [String]
    public var unchanged: [String]

    public init(insert: [String], update: [String], delete: [String], unchanged: [String]) {
        self.insert = insert
        self.update = update
        self.delete = delete
        self.unchanged = unchanged
    }

    public var writes: [String] {
        insert + update
    }
}

public enum IndexSyncCoordinator {
    /// Compares the last indexed fingerprints with the current ones.
    ///
    /// Identifiers are sorted so the plan is stable. A changed fingerprint is
    /// an update. Spotlight's `indexAppEntities` replaces an identifier that
    /// is already present, so inserts and updates can share one index call.
    public static func plan(indexed: [IndexedRecord], current: [IndexedRecord]) -> IndexSyncPlan {
        let indexedMap = Dictionary(indexed.map { ($0.identifier, $0.fingerprint) }, uniquingKeysWith: { _, latest in latest })
        let currentMap = Dictionary(current.map { ($0.identifier, $0.fingerprint) }, uniquingKeysWith: { _, latest in latest })
        var insert: [String] = []
        var update: [String] = []
        var unchanged: [String] = []
        for identifier in currentMap.keys.sorted() {
            if let previous = indexedMap[identifier] {
                if previous == currentMap[identifier] {
                    unchanged.append(identifier)
                } else {
                    update.append(identifier)
                }
            } else {
                insert.append(identifier)
            }
        }
        let delete = indexedMap.keys.filter { currentMap[$0] == nil }.sorted()
        return IndexSyncPlan(insert: insert, update: update, delete: delete, unchanged: unchanged)
    }

    public static func chunks<Element>(_ values: [Element], size: Int) -> [[Element]] {
        let step = max(1, size)
        guard !values.isEmpty else { return [] }
        var output: [[Element]] = []
        var index = values.startIndex
        while index < values.endIndex {
            let end = values.index(index, offsetBy: step, limitedBy: values.endIndex) ?? values.endIndex
            output.append(Array(values[index..<end]))
            index = end
        }
        return output
    }
}

public protocol IndexSnapshotStoring: Sendable {
    func snapshot(for typeName: String) async -> [IndexedRecord]
    func store(_ records: [IndexedRecord], for typeName: String) async
}

public actor MemoryIndexStore: IndexSnapshotStoring {
    private var snapshots: [String: [IndexedRecord]] = [:]

    public init() {}

    public func snapshot(for typeName: String) async -> [IndexedRecord] {
        snapshots[typeName] ?? []
    }

    public func store(_ records: [IndexedRecord], for typeName: String) async {
        snapshots[typeName] = records
    }
}

/// Holds the last accepted snapshot and plans the next index, update, and delete batch.
public actor IndexSyncSession {
    private let store: any IndexSnapshotStoring

    public init(store: any IndexSnapshotStoring) {
        self.store = store
    }

    public func plan(typeName: String, current: [IndexedRecord]) async -> IndexSyncPlan {
        let indexed = await store.snapshot(for: typeName)
        return IndexSyncCoordinator.plan(indexed: indexed, current: current)
    }

    public func accept(typeName: String, current: [IndexedRecord]) async {
        await store.store(current, for: typeName)
    }
}

public struct SpotlightMutation: Sendable, Equatable {
    public enum Action: String, Sendable, Equatable {
        case index
        case update
        case delete
    }

    public var action: Action
    public var identifiers: [String]

    public init(action: Action, identifiers: [String]) {
        self.action = action
        self.identifiers = identifiers
    }
}

public enum SpotlightBatchPlanner {
    public static let defaultBatchSize = 100

    public static func mutations(from plan: IndexSyncPlan, batchSize: Int = defaultBatchSize) -> [SpotlightMutation] {
        var mutations: [SpotlightMutation] = []
        for chunk in IndexSyncCoordinator.chunks(plan.insert, size: batchSize) {
            mutations.append(SpotlightMutation(action: .index, identifiers: chunk))
        }
        for chunk in IndexSyncCoordinator.chunks(plan.update, size: batchSize) {
            mutations.append(SpotlightMutation(action: .update, identifiers: chunk))
        }
        for chunk in IndexSyncCoordinator.chunks(plan.delete, size: batchSize) {
            mutations.append(SpotlightMutation(action: .delete, identifiers: chunk))
        }
        return mutations
    }
}

/// Fields used to build a `CSSearchableItem` when an entity is not indexed directly.
public struct SearchItemDraft: Sendable, Equatable {
    public var uniqueIdentifier: String
    public var domainIdentifier: String
    public var title: String
    public var contentDescription: String
    public var keywords: [String]

    public init(
        uniqueIdentifier: String,
        domainIdentifier: String,
        title: String,
        contentDescription: String,
        keywords: [String] = []
    ) {
        self.uniqueIdentifier = uniqueIdentifier
        self.domainIdentifier = domainIdentifier
        self.title = title
        self.contentDescription = contentDescription
        self.keywords = keywords
    }
}
