import Foundation
import SkillstrandCore

/// A platform-neutral description of one assistant tool.
///
/// On the iOS 27.3 SDK this maps to an `AppIntent` marked `@AppIntent(.tool)`,
/// with a title, a description, and a title plus description on every parameter.
/// The macro is compile-time only, so this value is what tests and the sample
/// studio share on every platform.
public struct ParameterSpec: Sendable, Equatable {
    public enum ValueType: String, Sendable, Equatable {
        case string
        case integer
        case boolean
        case date
        case entity
    }

    public var name: String
    public var title: String
    public var summary: String
    public var type: ValueType
    public var required: Bool
    public var entityType: String?

    public init(
        name: String,
        title: String,
        summary: String,
        type: ValueType,
        required: Bool = true,
        entityType: String? = nil
    ) {
        self.name = name
        self.title = title
        self.summary = summary
        self.type = type
        self.required = required
        self.entityType = entityType
    }
}

@resultBuilder
public enum ParameterBuilder {
    public static func buildBlock(_ components: [ParameterSpec]...) -> [ParameterSpec] {
        components.flatMap { $0 }
    }

    public static func buildExpression(_ expression: ParameterSpec) -> [ParameterSpec] {
        [expression]
    }

    public static func buildOptional(_ component: [ParameterSpec]?) -> [ParameterSpec] {
        component ?? []
    }

    public static func buildEither(first component: [ParameterSpec]) -> [ParameterSpec] {
        component
    }

    public static func buildEither(second component: [ParameterSpec]) -> [ParameterSpec] {
        component
    }

    public static func buildArray(_ components: [[ParameterSpec]]) -> [ParameterSpec] {
        components.flatMap { $0 }
    }
}

public struct IntentBlueprint: Sendable, Equatable {
    public var name: String
    public var title: String
    public var summary: String
    /// When true, the intent is meant to be exposed with `@AppIntent(.tool)`.
    public var toolEligible: Bool
    public var parameters: [ParameterSpec]

    public init(
        name: String,
        title: String,
        summary: String,
        toolEligible: Bool = true,
        @ParameterBuilder parameters: () -> [ParameterSpec]
    ) {
        self.name = name
        self.title = title
        self.summary = summary
        self.toolEligible = toolEligible
        self.parameters = parameters()
    }
}

/// Turns a ``SkillFailure`` into the dialog string an intent should throw or speak.
public enum SkillErrorMapping {
    public static func lead(for code: SkillFailureCode) -> String {
        switch code {
        case .emptyInput: "Needs a value"
        case .notFound: "Nothing matched"
        case .ambiguous: "Needs a choice"
        case .cancelled: "Cancelled"
        case .invalidDocument: "Skill file"
        case .indexRejected: "Index"
        case .unavailable: "Unavailable"
        }
    }

    public static func dialog(for failure: SkillFailure) -> DialogCopy {
        let kind: DialogCopy.Kind = failure.code == .cancelled ? .cancelled : .failure
        return DialogCopy(text: "\(lead(for: failure.code)): \(failure.message)", kind: kind)
    }

    public static func failed(_ failure: SkillFailure, skillName: String, steps: [SkillStep]) -> SkillRun {
        SkillRun(
            skillName: skillName,
            steps: steps,
            outcome: .failed(failure),
            dialog: dialog(for: failure)
        )
    }
}
