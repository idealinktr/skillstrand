import Foundation

#if canImport(AppIntents)
import AppIntents

public enum SkillstrandEntitiesAvailability {
    public static let appleFrameworksLinked = true
}

@available(iOS 16.0, macOS 13.0, *)
public enum EntityDisplayMapping {
    public static func representation(title: String, subtitle: String?) -> DisplayRepresentation {
        if let subtitle, !subtitle.isEmpty {
            return DisplayRepresentation(title: "\(title)", subtitle: "\(subtitle)")
        }
        return DisplayRepresentation(title: "\(title)")
    }

    public static func typeRepresentation(name: String) -> TypeDisplayRepresentation {
        TypeDisplayRepresentation(name: LocalizedStringResource(stringLiteral: name))
    }
}

#else

public enum SkillstrandEntitiesAvailability {
    public static let appleFrameworksLinked = false
}

#endif
