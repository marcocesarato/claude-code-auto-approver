import AutoApproverCore
import Foundation

enum Settings {
    /// How often the Claude window and the notifications are searched for a prompt.
    static let pollInterval: TimeInterval = 1.5

    private static let folder = "ClaudeCodeAutoApprover"
    private static let home = FileManager.default.homeDirectoryForCurrentUser.path

    /// Labels to press, one per line; absent or empty means the default.
    static let labelsPath = "\(home)/Library/Application Support/\(folder)/labels.txt"
    /// Titles of the chats left alone, one per line; written from the menu.
    static let skippedChatsPath = "\(home)/Library/Application Support/\(folder)/skipped-chats.txt"
    static let logPath = "\(home)/Library/Logs/\(folder).log"

    static func readLabels() -> String? { try? String(contentsOfFile: labelsPath, encoding: .utf8) }

    static func readSkippedChats() -> String? { try? String(contentsOfFile: skippedChatsPath, encoding: .utf8) }

    static func toggleSkipped(_ title: String) {
        let url = URL(fileURLWithPath: skippedChatsPath)
        do {
            try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
            try Chats.toggled(title, inFile: readSkippedChats()).write(to: url, atomically: true, encoding: .utf8)
        } catch {
            log("❌ Could not save the skipped chats: \(error.localizedDescription)")
        }
    }

    static var version: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "dev"
    }
}
