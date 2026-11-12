import Skillstrand
import SwiftUI

struct IndexStudio: View {
    @State private var items = SearchAndOpenSkill.starterCatalog
    @State private var plan = IndexSyncPlan(insert: [], update: [], delete: [], unchanged: [])
    @State private var session = IndexSyncSession(store: MemoryIndexStore())

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text("Compare the library with the last accepted Spotlight snapshot. Inserts and updates share one index call on device. Deletes are a separate batch.")
                    .font(.title3)
                StrandCard {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(items) { item in
                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.title).font(.headline)
                                Text(item.summary).font(.callout).foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 4)
                        }
                        ChoiceButton(title: "Revise the kiln log", prominent: true) {
                            guard let index = items.firstIndex(where: { $0.id == "kiln" }) else { return }
                            items[index].summary = "Last firing, cone 6, a cooler top shelf."
                            Task { await refresh() }
                        }
                        ChoiceButton(title: "Accept this snapshot") {
                            Task {
                                await session.accept(typeName: "LibraryItem", current: records)
                                await refresh()
                            }
                        }
                    }
                }
                StrandCard {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Plan").font(.headline)
                        Text("Index \(plan.insert.joined(separator: ", ").ifEmpty("none"))")
                        Text("Update \(plan.update.joined(separator: ", ").ifEmpty("none"))")
                        Text("Delete \(plan.delete.joined(separator: ", ").ifEmpty("none"))")
                        Text("Unchanged \(plan.unchanged.joined(separator: ", ").ifEmpty("none"))")
                            .foregroundStyle(.secondary)
                    }
                    .font(.callout.monospaced())
                }
            }
            .padding(20)
            .frame(maxWidth: 720, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(StrandTheme.paper)
        .navigationTitle("Spotlight plan")
        .task { await refresh() }
    }

    private var records: [IndexedRecord] {
        items.map { IndexedRecord(identifier: $0.id, fingerprint: $0.fingerprint) }
    }

    private func refresh() async {
        plan = await session.plan(typeName: "LibraryItem", current: records)
    }
}

private extension String {
    func ifEmpty(_ fallback: String) -> String {
        isEmpty ? fallback : self
    }
}
