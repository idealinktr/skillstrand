import Foundation

#if SKILLSTRAND_IOS_27_3_SDK && canImport(AppIntents)
import AppIntents

/// The `.tool` trait is present in the iOS 27.3 SDK. CI sets
/// `SKILLSTRAND_IOS_27_3_SDK` only after it finds an Xcode 27.3 beta.
/// The stable intents in the package stay available without the trait so an
/// older toolchain can still build the sample.
@available(iOS 27.3, macOS 27.3, *)
@AppIntent(.tool)
struct CreateTaskTool: AppIntent {
    static let title: LocalizedStringResource = "Create Task"
    static let description = IntentDescription("Creates a task from a title the person has confirmed.")

    @Parameter(title: "Title", description: "The task title the person confirmed.")
    var title: String

    init() {
        title = ""
    }

    func perform() async throws -> some IntentResult {
        .result(dialog: "Created the task \(title).")
    }
}

@available(iOS 27.3, macOS 27.3, *)
@AppIntent(.tool)
struct ScheduleReminderTool: AppIntent {
    static let title: LocalizedStringResource = "Schedule Reminder"
    static let description = IntentDescription("Schedules a reminder for one confirmed time.")

    @Parameter(title: "Title", description: "What the reminder is for.")
    var title: String

    @Parameter(title: "When", description: "The single time the person picked.")
    var when: String

    init() {
        title = ""
        when = ""
    }

    func perform() async throws -> some IntentResult {
        .result(dialog: "Scheduled \(title) for \(when).")
    }
}
#endif
