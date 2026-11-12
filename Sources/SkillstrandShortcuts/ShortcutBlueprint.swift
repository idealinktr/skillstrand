import Foundation

/// A checkable description of one `AppShortcutsProvider` entry.
///
/// App Shortcut phrases are compile-time strings. Each one has to include the
/// application name token, written `{applicationName}` here and
/// `\(.applicationName)` in Swift. ``AppShortcutsSource`` renders that Swift.
public struct ShortcutBlueprint: Sendable, Equatable {
    public var intentName: String
    public var phraseTemplates: [String]
    public var shortTitle: String
    public var systemImageName: String

    public init(intentName: String, phraseTemplates: [String], shortTitle: String, systemImageName: String) {
        self.intentName = intentName
        self.phraseTemplates = phraseTemplates
        self.shortTitle = shortTitle
        self.systemImageName = systemImageName
    }

    public func validate() throws {
        guard !phraseTemplates.isEmpty else {
            throw ShortcutBlueprintError.emptyPhrases
        }
        for phrase in phraseTemplates {
            guard phrase.contains("{applicationName}") else {
                throw ShortcutBlueprintError.missingApplicationName(phrase)
            }
        }
        guard !shortTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ShortcutBlueprintError.emptyShortTitle
        }
        guard !systemImageName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ShortcutBlueprintError.emptySymbol
        }
    }
}

public enum ShortcutBlueprintError: Error, Sendable, Equatable {
    case emptyPhrases
    case missingApplicationName(String)
    case emptyShortTitle
    case emptySymbol
}

public enum AppShortcutsSource {
    /// Renders an `AppShortcutsProvider` the sample app, and Xcode file templates, can paste.
    public static func render(typeName: String, blueprints: [ShortcutBlueprint]) throws -> String {
        for blueprint in blueprints {
            try blueprint.validate()
        }
        var lines: [String] = []
        lines.append("import AppIntents")
        lines.append("")
        lines.append("struct \(typeName): AppShortcutsProvider {")
        lines.append("    static var appShortcuts: [AppShortcut] {")
        lines.append("        [")
        for blueprint in blueprints {
            lines.append("            AppShortcut(")
            lines.append("                intent: \(blueprint.intentName)(),")
            lines.append("                phrases: [")
            for phrase in blueprint.phraseTemplates {
                let rendered = escape(phrase).replacingOccurrences(
                    of: "{applicationName}",
                    with: "\\(.applicationName)"
                )
                lines.append("                    \"\(rendered)\",")
            }
            lines.append("                ],")
            lines.append("                shortTitle: \"\(escape(blueprint.shortTitle))\",")
            lines.append("                systemImageName: \"\(escape(blueprint.systemImageName))\"")
            lines.append("            ),")
        }
        lines.append("        ]")
        lines.append("    }")
        lines.append("}")
        lines.append("")
        return lines.joined(separator: "\n")
    }

    private static func escape(_ value: String) -> String {
        value
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
    }
}

#if canImport(AppIntents)
import AppIntents

public enum SkillstrandShortcutsAvailability {
    public static let appleFrameworksLinked = true
}

@available(iOS 16.0, macOS 13.0, *)
public enum AppShortcutsBuilder {
    public static func assertValid(_ blueprints: [ShortcutBlueprint]) throws {
        for blueprint in blueprints {
            try blueprint.validate()
        }
    }
}

#else

public enum SkillstrandShortcutsAvailability {
    public static let appleFrameworksLinked = false
}

public enum AppShortcutsBuilder {
    public static func assertValid(_ blueprints: [ShortcutBlueprint]) throws {
        for blueprint in blueprints {
            try blueprint.validate()
        }
    }
}

#endif
