import AppIntents
import Skillstrand

/// Discovered by the system from the app target. Phrases include the application name,
/// which `ShortcutBlueprint` checks for before this file is written.
@available(iOS 18.0, macOS 15.0, *)
struct SampleShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: CreateTaskIntent(),
            phrases: [
                "Capture a task with \(.applicationName)",
                "Save a to-do in \(.applicationName)",
            ],
            shortTitle: "Capture task",
            systemImageName: "checkmark.circle"
        )
        AppShortcut(
            intent: OpenLibraryItemIntent(),
            phrases: [
                "Open \(.applicationName)",
                "Find something in \(.applicationName)",
            ],
            shortTitle: "Open item",
            systemImageName: "magnifyingglass"
        )
        AppShortcut(
            intent: ShareSummaryIntent(),
            phrases: [
                "Share a summary with \(.applicationName)",
            ],
            shortTitle: "Share summary",
            systemImageName: "square.and.arrow.up"
        )
        AppShortcut(
            intent: ScheduleReminderIntent(),
            phrases: [
                "Set a reminder in \(.applicationName)",
            ],
            shortTitle: "Set reminder",
            systemImageName: "bell"
        )
    }
}
