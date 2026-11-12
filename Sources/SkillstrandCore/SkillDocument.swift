import Foundation

/// A parsed app-skill file.
///
/// The on-disk rules match the skills bundle documented for the iOS 27.3 beta:
/// `name` and `description` front matter only, then a Markdown body. Siri AI
/// treats the body as guidance, not as a script it must run step by step.
public struct SkillDocument: Sendable, Equatable {
    public var name: String
    public var summary: String
    public var body: String
    public var directoryName: String?

    public init(name: String, summary: String, body: String, directoryName: String? = nil) {
        self.name = name
        self.summary = summary
        self.body = body
        self.directoryName = directoryName
    }
}

public enum SkillDocumentError: Error, Sendable, Equatable, CustomStringConvertible {
    case missingFrontMatter
    case unsupportedField(String)
    case missingField(String)
    case invalidName(String)
    case invalidDescription(String)
    case emptyBody
    case directoryMismatch(directory: String, name: String)
    case missingSkillsDirectory(String)
    case unexpectedEntry(String)
    case unreadable(String)

    public var description: String {
        switch self {
        case .missingFrontMatter:
            return "SKILL.md must start with name and description front matter."
        case .unsupportedField(let field):
            return "Unsupported front matter field \"\(field)\". Only name and description are allowed."
        case .missingField(let field):
            return "Missing required front matter field \"\(field)\"."
        case .invalidName(let name):
            return "Invalid skill name \"\(name)\". Use 1-64 lowercase letters, digits, and single hyphens."
        case .invalidDescription(let reason):
            return "Invalid description: \(reason)"
        case .emptyBody:
            return "The skill body is empty."
        case .directoryMismatch(let directory, let name):
            return "Directory \"\(directory)\" does not match skill name \"\(name)\"."
        case .missingSkillsDirectory(let path):
            return "No Skills directory at \(path)."
        case .unexpectedEntry(let path):
            return "Skills bundles can only contain a skill directory and SKILL.md, found \(path)."
        case .unreadable(let path):
            return "Could not read \(path)."
        }
    }
}

public enum SkillDocumentParser {
    public static let maximumNameLength = 64
    public static let maximumDescriptionLength = 1024

    /// Parses one `SKILL.md` string.
    /// - Parameter raw: The full file text, including the front matter.
    /// - Parameter directoryName: When set, it must equal the `name` field.
    public static func parse(_ raw: String, directoryName: String? = nil) throws -> SkillDocument {
        let text = raw
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")
        guard text.hasPrefix("---\n") else {
            throw SkillDocumentError.missingFrontMatter
        }
        let rest = text.dropFirst(4)
        guard let closing = rest.range(of: "\n---") else {
            throw SkillDocumentError.missingFrontMatter
        }
        let frontMatter = String(rest[..<closing.lowerBound])
        var body = String(rest[closing.upperBound...])
        if body.hasPrefix("\n") {
            body.removeFirst()
        }
        let trimmedBody = body.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedBody.isEmpty else {
            throw SkillDocumentError.emptyBody
        }

        var fields: [String: String] = [:]
        for lineSub in frontMatter.split(separator: "\n", omittingEmptySubsequences: false) {
            let line = String(lineSub).trimmingCharacters(in: .whitespaces)
            if line.isEmpty { continue }
            guard let separator = line.firstIndex(of: ":") else {
                throw SkillDocumentError.unsupportedField(line)
            }
            let key = String(line[..<separator]).trimmingCharacters(in: .whitespaces)
            let rawValue = String(line[line.index(after: separator)...]).trimmingCharacters(in: .whitespaces)
            guard key == "name" || key == "description" else {
                throw SkillDocumentError.unsupportedField(key)
            }
            guard fields[key] == nil else {
                throw SkillDocumentError.unsupportedField(key)
            }
            fields[key] = unwrap(rawValue)
        }

        guard let name = fields["name"], !name.isEmpty else {
            throw SkillDocumentError.missingField("name")
        }
        guard let summary = fields["description"], !summary.isEmpty else {
            throw SkillDocumentError.missingField("description")
        }
        try validateName(name)
        try validateDescription(summary)
        if let directoryName, directoryName != name {
            throw SkillDocumentError.directoryMismatch(directory: directoryName, name: name)
        }
        return SkillDocument(name: name, summary: summary, body: trimmedBody, directoryName: directoryName)
    }

    public static func validateName(_ name: String) throws {
        guard (1...maximumNameLength).contains(name.count) else {
            throw SkillDocumentError.invalidName(name)
        }
        guard !name.hasPrefix("-"), !name.hasSuffix("-"), !name.contains("--") else {
            throw SkillDocumentError.invalidName(name)
        }
        let allowed = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyz0123456789-")
        guard name.unicodeScalars.allSatisfy({ allowed.contains($0) }) else {
            throw SkillDocumentError.invalidName(name)
        }
    }

    public static func validateDescription(_ summary: String) throws {
        if summary.contains("\n") {
            throw SkillDocumentError.invalidDescription("keep it on one line")
        }
        if summary.count > maximumDescriptionLength {
            throw SkillDocumentError.invalidDescription("longer than \(maximumDescriptionLength) characters")
        }
    }

    private static func unwrap(_ value: String) -> String {
        guard value.count >= 2 else { return value }
        let first = value.first
        let last = value.last
        if (first == "\"" && last == "\"") || (first == "'" && last == "'") {
            return String(value.dropFirst().dropLast())
        }
        return value
    }
}

public enum SkillBundleValidator {
    /// Loads every skill under a `Skills` directory or a `*.skillsbundle` root.
    public static func load(at root: URL) throws -> [SkillDocument] {
        let skillsRoot: URL
        if root.lastPathComponent.hasSuffix(".skillsbundle") {
            skillsRoot = root.appendingPathComponent("Skills", isDirectory: true)
        } else {
            skillsRoot = root
        }
        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: skillsRoot.path, isDirectory: &isDirectory), isDirectory.boolValue else {
            throw SkillDocumentError.missingSkillsDirectory(skillsRoot.path)
        }
        let entries = try FileManager.default.contentsOfDirectory(
            at: skillsRoot,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        )
        var documents: [SkillDocument] = []
        for entry in entries.sorted(by: { $0.lastPathComponent < $1.lastPathComponent }) {
            let values = try entry.resourceValues(forKeys: [.isDirectoryKey])
            guard values.isDirectory == true else {
                throw SkillDocumentError.unexpectedEntry(entry.lastPathComponent)
            }
            let children = try FileManager.default.contentsOfDirectory(at: entry, includingPropertiesForKeys: nil)
            guard children.count == 1, children[0].lastPathComponent == "SKILL.md" else {
                let names = children.map(\.lastPathComponent).sorted().joined(separator: ", ")
                throw SkillDocumentError.unexpectedEntry("\(entry.lastPathComponent)/\(names)")
            }
            guard let raw = try? String(contentsOf: children[0], encoding: .utf8) else {
                throw SkillDocumentError.unreadable(children[0].path)
            }
            documents.append(try SkillDocumentParser.parse(raw, directoryName: entry.lastPathComponent))
        }
        return documents
    }
}
