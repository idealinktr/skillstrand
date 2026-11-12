import Foundation
import SkillstrandCore

#if canImport(AppIntents)
import AppIntents

public enum SkillstrandIntentsAvailability {
    public static let appleFrameworksLinked = true
}

@available(iOS 16.0, macOS 13.0, *)
public enum SkillIntentResults {
    public static func intentDialog(_ copy: DialogCopy) -> IntentDialog {
        IntentDialog(stringLiteral: copy.text)
    }

    public static func success(_ copy: DialogCopy) -> IntentDialog {
        intentDialog(copy)
    }
}

@available(iOS 16.0, macOS 13.0, *)
extension SkillFailure: CustomLocalizedStringResourceConvertible {
    public var localizedStringResource: LocalizedStringResource {
        LocalizedStringResource(stringLiteral: SkillErrorMapping.dialog(for: self).text)
    }
}

@available(iOS 16.0, macOS 13.0, *)
public extension AppIntent {
    /// Asks the system to confirm before a tool writes anything.
    ///
    /// `requestConfirmation(dialog:)` is the App Intents call. The prompt's
    /// confirm and deny labels stay on ``ConfirmationPrompt`` for in-app
    /// previews; the system dialog uses the standard confirm action.
    func confirm(_ prompt: ConfirmationPrompt) async throws {
        try await requestConfirmation(dialog: IntentDialog(stringLiteral: prompt.text))
    }
}

/// How a missing parameter is filled inside an intent body.
///
/// The projection call is only valid on an `@Parameter` property:
/// `try await $title.requestValue(IntentDialog("What should the task be called?"))`.
public enum ValueRequestGuide {
    public static let sourceHint =
        "try await $title.requestValue(IntentDialog(\"What should the task be called?\"))"
}

/// How several matches are narrowed inside an intent body.
///
/// `requestDisambiguation(among:dialog:)` is a method on the `@Parameter`
/// projection, not on `AppIntent`:
/// `try await $item.requestDisambiguation(among: matches, dialog: IntentDialog("Which one?"))`.
/// The projection only exists on a stored parameter, so this module cannot wrap the call.
public enum DisambiguationRequestGuide {
    public static let sourceHint =
        "try await $item.requestDisambiguation(among: matches, dialog: IntentDialog(\"Which one?\"))"
}

#else

public enum SkillstrandIntentsAvailability {
    public static let appleFrameworksLinked = false
}

public enum ValueRequestGuide {
    public static let sourceHint =
        "try await $title.requestValue(IntentDialog(\"What should the task be called?\"))"
}

public enum DisambiguationRequestGuide {
    public static let sourceHint =
        "try await $item.requestDisambiguation(among: matches, dialog: IntentDialog(\"Which one?\"))"
}

#endif
