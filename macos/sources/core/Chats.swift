import Foundation

/// Chats the user keeps for themselves: their prompts are left unanswered.
public enum Chats {
    /// An open chat's header carries its menu button, labelled with the chat's title.
    static let menuPrefix = "More options for "

    public static func title(fromMenuButton label: String) -> String? {
        guard label.hasPrefix(menuPrefix) else { return nil }
        let title = label.dropFirst(menuPrefix.count).trimmingCharacters(in: .whitespaces)
        return title.isEmpty ? nil : title
    }

    /// A sidebar row's button reads "<title> <status>". Returns the title of a chat that is
    /// not idle — running, or waiting for an answer — and nil otherwise.
    public static func activeTitle(rowLabel: String, status: String) -> String? {
        let status = status.trimmingCharacters(in: .whitespaces)
        guard !status.isEmpty, status.lowercased() != "idle" else { return nil }
        var title = rowLabel.trimmingCharacters(in: .whitespaces)
        if title.hasSuffix(status) { title = String(title.dropLast(status.count)).trimmingCharacters(in: .whitespaces) }
        return title.isEmpty ? nil : title
    }

    /// The titles listed in the skip file, one per line; `#` starts a comment.
    public static func skipped(fromFile text: String?) -> [String] {
        (text ?? "").split(whereSeparator: \.isNewline)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty && !$0.hasPrefix("#") }
    }

    /// The skip file with `title` added, or removed when already listed.
    public static func toggled(_ title: String, inFile text: String?) -> String {
        var titles = skipped(fromFile: text)
        if let i = titles.firstIndex(where: { same($0, title) }) { titles.remove(at: i) } else { titles.append(title) }
        return titles.map { $0 + "\n" }.joined()
    }

    /// The chats to offer: the skipped ones even when closed, so each can be undone, then the
    /// open ones not skipped, sorted as Finder sorts names.
    public static func listed(open: [String], skipped: [String]) -> [String] {
        var titles = skipped
        for chat in open where !isSkipped(chat, titles) { titles.append(chat) }
        return titles.sorted { $0.localizedStandardCompare($1) == .orderedAscending }
    }

    public static func isSkipped(_ title: String?, _ skipped: [String]) -> Bool {
        guard let title else { return false }
        return skipped.contains { same($0, title) }
    }

    /// A banner names its chat in its text ("Claude, <project>, <chat>, Allow Claude to …").
    /// A title found anywhere in it counts, so a doubtful match skips rather than approves.
    public static func bannerIsSkipped(_ text: String, _ skipped: [String]) -> Bool {
        let text = text.lowercased()
        return skipped.contains { text.contains($0.lowercased()) }
    }

    private static func same(_ a: String, _ b: String) -> Bool {
        a.compare(b, options: [.caseInsensitive, .diacriticInsensitive]) == .orderedSame
    }
}
