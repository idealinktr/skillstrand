import Foundation

public struct SkillStep: Sendable, Equatable {
    public var id: String
    public var detail: String

    public init(id: String, detail: String) {
        self.id = id
        self.detail = detail
    }
}

public enum ConfirmationAnswer: Sendable, Equatable {
    case confirmed
    case denied
}

public struct ConfirmationPrompt: Sendable, Equatable {
    public var parameter: String
    public var text: String
    public var confirmLabel: String
    public var denyLabel: String

    public init(parameter: String, text: String, confirmLabel: String, denyLabel: String) {
        self.parameter = parameter
        self.text = text
        self.confirmLabel = confirmLabel
        self.denyLabel = denyLabel
    }
}

public struct DisambiguationOption: Sendable, Equatable, Identifiable {
    public var id: String
    public var label: String

    public init(id: String, label: String) {
        self.id = id
        self.label = label
    }
}

public struct DisambiguationPrompt: Sendable, Equatable {
    public var parameter: String
    public var text: String
    public var options: [DisambiguationOption]

    public init(parameter: String, text: String, options: [DisambiguationOption]) {
        self.parameter = parameter
        self.text = text
        self.options = options
    }
}

public struct ValuePrompt: Sendable, Equatable {
    public var parameter: String
    public var text: String

    public init(parameter: String, text: String) {
        self.parameter = parameter
        self.text = text
    }
}

public enum SkillFailureCode: String, Sendable, Equatable, CaseIterable {
    case emptyInput
    case notFound
    case ambiguous
    case cancelled
    case invalidDocument
    case indexRejected
    case unavailable
}

public struct SkillFailure: Error, Sendable, Equatable {
    public var code: SkillFailureCode
    public var message: String

    public init(code: SkillFailureCode, message: String) {
        self.code = code
        self.message = message
    }
}

public struct DialogCopy: Sendable, Equatable {
    public enum Kind: String, Sendable, Equatable {
        case success
        case confirmation
        case disambiguation
        case value
        case failure
        case cancelled
    }

    public var text: String
    public var kind: Kind

    public init(text: String, kind: Kind) {
        self.text = text
        self.kind = kind
    }
}

public enum SkillOutcome: Sendable, Equatable {
    case needsConfirmation(ConfirmationPrompt)
    case needsDisambiguation(DisambiguationPrompt)
    case needsValue(ValuePrompt)
    case completed(String)
    case cancelled(String)
    case failed(SkillFailure)
}

public struct SkillRun: Sendable, Equatable {
    public var skillName: String
    public var steps: [SkillStep]
    public var outcome: SkillOutcome
    public var dialog: DialogCopy

    public init(skillName: String, steps: [SkillStep], outcome: SkillOutcome, dialog: DialogCopy) {
        self.skillName = skillName
        self.steps = steps
        self.outcome = outcome
        self.dialog = dialog
    }
}

public enum DialogComposer {
    public static func success(_ text: String) -> DialogCopy {
        DialogCopy(text: text, kind: .success)
    }

    public static func confirmation(_ prompt: ConfirmationPrompt) -> DialogCopy {
        DialogCopy(text: prompt.text, kind: .confirmation)
    }

    public static func disambiguation(_ prompt: DisambiguationPrompt) -> DialogCopy {
        DialogCopy(text: prompt.text, kind: .disambiguation)
    }

    public static func value(_ prompt: ValuePrompt) -> DialogCopy {
        DialogCopy(text: prompt.text, kind: .value)
    }

    public static func cancelled(_ text: String) -> DialogCopy {
        DialogCopy(text: text, kind: .cancelled)
    }
}
