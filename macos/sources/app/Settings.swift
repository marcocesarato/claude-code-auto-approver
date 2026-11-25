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

    /// Saves the labels to press; the monitor reads them on its next tick.
    static func writeLabels(_ text: String) -> Bool {
        let url = URL(fileURLWithPath: labelsPath)
        do {
            try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
            try text.write(to: url, atomically: true, encoding: .utf8)
            log("🏷 Labels saved")
            return true
        } catch {
            log("❌ Could not save the labels: \(error.localizedDescription)")
            return false
        }
    }

    /// The end of the log: enough for the recent approvals, cheap to read every few seconds.
    /// A line cut by the start of the read is dropped.
    static func readLogTail(bytes: UInt64 = 64 * 1024) -> String {
        guard let handle = FileHandle(forReadingAtPath: logPath) else { return "" }
        defer { try? handle.close() }
        let end = (try? handle.seekToEnd()) ?? 0
        let start = end > bytes ? end - bytes : 0
        try? handle.seek(toOffset: start)
        let text = String(decoding: (try? handle.readToEnd()) ?? Data(), as: UTF8.self)
        guard start > 0, let newline = text.firstIndex(of: "\n") else { return text }
        return String(text[text.index(after: newline)...])
    }

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
