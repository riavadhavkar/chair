//
//  Secrets.swift
//  sair
//

import Foundation

/// Development-only secrets loader. Reads key/value pairs from a gitignored
/// `Secrets.xcconfig` file at the repo root so API keys never get committed.
///
/// This intentionally bypasses Xcode's build-setting substitution (wiring a
/// real "Based on Configuration File" association requires editing
/// project.pbxproj directly, which this project's tooling avoids) and just
/// reads the file straight off disk using its own source location as an
/// anchor. That only works while running from a source checkout on the
/// machine that built it — it is not a distribution-safe secrets mechanism.
enum Secrets {
    static let backendBaseURL: URL = {
        guard let raw = value(for: "SETWATCH_BACKEND_BASE_URL"), let url = URL(string: raw) else {
            return URL(string: "http://localhost:8080")!
        }
        return url
    }()

    static let elevenLabsAPIKey: String? = value(for: "ELEVENLABS_API_KEY")

    private static let entries: [String: String] = loadEntries()

    private static func value(for key: String) -> String? {
        guard let raw = entries[key], !raw.isEmpty else { return nil }
        return raw
    }

    private static func loadEntries() -> [String: String] {
        let repoRoot = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent() // Models
            .deletingLastPathComponent() // sair (source folder)
            .deletingLastPathComponent() // repo root
        let secretsURL = repoRoot.appendingPathComponent("Secrets.xcconfig")

        guard let contents = try? String(contentsOf: secretsURL, encoding: .utf8) else {
            return [:]
        }

        var result: [String: String] = [:]
        for line in contents.split(whereSeparator: \.isNewline) {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty, !trimmed.hasPrefix("//"), let separatorIndex = trimmed.firstIndex(of: "=") else {
                continue
            }
            let key = trimmed[trimmed.startIndex..<separatorIndex].trimmingCharacters(in: .whitespaces)
            let value = trimmed[trimmed.index(after: separatorIndex)...].trimmingCharacters(in: .whitespaces)
            result[key] = value
        }
        return result
    }
}
