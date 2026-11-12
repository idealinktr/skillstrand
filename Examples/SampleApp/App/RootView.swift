import Skillstrand
import SwiftUI

enum SampleSection: Hashable {
    case skill(String)
    case index
}

struct RootView: View {
    @State private var selection: SampleSection? = .skill(CaptureToTaskSkill.name)

    var body: some View {
        NavigationSplitView {
            List(selection: $selection) {
                Section("Skills") {
                    ForEach(ExampleSkillCatalog.all) { skill in
                        NavigationLink(value: SampleSection.skill(skill.name)) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(skill.title)
                                    .font(.body.weight(.semibold))
                                Text(skill.name)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                Section("Index") {
                    NavigationLink(value: SampleSection.index) {
                        Text("Spotlight plan")
                    }
                }
            }
            .navigationTitle("Skillstrand")
            .scrollContentBackground(.hidden)
            .background(StrandTheme.paper)
        } detail: {
            detail
        }
        .background(StrandTheme.paper)
    }

    @ViewBuilder
    private var detail: some View {
        switch selection {
        case .skill(let name):
            if let skill = ExampleSkillCatalog.all.first(where: { $0.name == name }) {
                SkillStudio(skill: skill)
            } else {
                ContentUnavailableView("Missing skill", systemImage: "questionmark")
            }
        case .index:
            IndexStudio()
        case nil:
            ContentUnavailableView("Choose a skill", systemImage: "point.3.connected.trianglepath.dotted")
        }
    }
}
