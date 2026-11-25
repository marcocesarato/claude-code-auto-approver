import Foundation

/// One button the app pressed, read back from its log.
public struct Approval: Equatable, Sendable {
    /// "2026-11-25 10:42:07", as the log stamps it.
    public let time: String
    public let label: String
    /// Pressed on a notification banner, rather than in the Claude window.
    public let fromNotification: Bool
    /// Pressed while the screen was locked.
    public let locked: Bool
    /// The chat the request came from, and what it asked, when the app could read them.
    public let chat: String?
    public let request: String?

    public init(time: String, label: String, fromNotification: Bool, locked: Bool,
                chat: String? = nil, request: String? = nil) {
        self.time = time
        self.label = label
        self.fromNotification = fromNotification
        self.locked = locked
        self.chat = chat
        self.request = request
    }

    public var day: String { String(time.prefix(10)) }
    /// "10:42".
    public var clock: String { String(time.dropFirst(11).prefix(5)) }
}

/// A button the app pressed, with the chat and the request it answered when they could be read.
public struct Pressed: Sendable {
    public let label: String
    public let chat: String?
    public let request: String?

    public init(label: String, chat: String?, request: String?) {
        self.label = label
        self.chat = chat
        self.request = request
    }
}

public enum Activity {
    static let notificationSuffix = " (notification)"

    /// The line the monitor logs for an approval, after the time:
    /// `🤖 Approved #3: pressed "Allow once (notification)" 🔒 in "Fix tests": Allow Claude to run ls`.
    /// The lock, the chat and the request are each left out when they do not apply.
    public static func logLine(number: Int, label: String, locked: Bool, chat: String?, request: String?) -> String {
        var line = "🤖 Approved #\(number): pressed \"\(label)\""
        if locked { line += " 🔒" }
        if let chat, !chat.isEmpty { line += " in \"\(chat)\"" }
        if let request, !request.isEmpty { line += ": " + request.replacingOccurrences(of: "\n", with: " ").prefix(240) }
        return line
    }

    /// The approvals in `log`, newest first: the lines `logLine` writes, and the older ones
    /// that carried only the label and the lock.
    public static func approvals(fromLog log: String) -> [Approval] {
        // Lines older than the chat and the request take them from the banner logged before them.
        var banner: (chat: String?, request: String?) = (nil, nil)
        return log.split(whereSeparator: \.isNewline).compactMap { line -> Approval? in
            if let mark = line.range(of: bannerMarker) {
                banner = bannerRequest(String(line[mark.upperBound...]))
                return nil
            }
            guard var approval = approval(line) else { return nil }
            if approval.fromNotification, approval.chat == nil, approval.request == nil {
                approval = Approval(time: approval.time, label: approval.label, fromNotification: true,
                                    locked: approval.locked, chat: banner.chat, request: banner.request)
            }
            return approval
        }.reversed()
    }

    static let bannerMarker = "🔔 Permission notification: "

    private static func approval(_ line: Substring) -> Approval? {
        guard let marker = line.range(of: " 🤖 Approved #"),
              let open = line.range(of: "pressed \"", range: marker.upperBound..<line.endIndex),
              let close = line.range(of: "\"", range: open.upperBound..<line.endIndex) else { return nil }
        var label = String(line[open.upperBound..<close.lowerBound])
        let banner = label.hasSuffix(notificationSuffix)
        if banner { label = String(label.dropLast(notificationSuffix.count)) }
        var rest = line[close.upperBound...]
        let locked = rest.hasPrefix(" 🔒")
        if locked { rest = rest.dropFirst(2) }
        var chat: String?
        // A chat title may hold quotes: it ends at the quote the request or the line follows.
        if rest.hasPrefix(" in \"") {
            let body = rest.dropFirst(5)
            let end = body.indices.first { body[$0] == "\"" && (body[body.index(after: $0)...].isEmpty
                || body[body.index(after: $0)...].hasPrefix(": ")) }
            if let end {
                chat = String(body[..<end])
                rest = body[body.index(after: end)...]
            }
        }
        let request = rest.hasPrefix(": ") ? String(rest.dropFirst(2)) : nil
        return Approval(time: String(line[..<marker.lowerBound]), label: label, fromNotification: banner,
                        locked: locked, chat: chat, request: request)
    }

    /// A banner reads "Claude, <project>, <chat>, Allow Claude to …": the chat and the request.
    public static func bannerRequest(_ text: String) -> (chat: String?, request: String?) {
        guard let start = text.range(of: Labels.permissionBanner, options: .caseInsensitive) else { return (nil, nil) }
        let request = String(text[start.lowerBound...]).trimmingCharacters(in: .whitespaces)
        let before = text[..<start.lowerBound].trimmingCharacters(in: CharacterSet(charactersIn: ", "))
        let parts = before.components(separatedBy: ", ")
        let chat = parts.count >= 3 ? parts.dropFirst(2).joined(separator: ", ") : parts.count == 2 ? parts[1] : nil
        return (chat, request)
    }

    /// The approvals grouped by day, newest day first, in the order given.
    public static func byDay(_ approvals: [Approval]) -> [(day: String, approvals: [Approval])] {
        var days: [(day: String, approvals: [Approval])] = []
        for approval in approvals {
            if days.last?.day == approval.day { days[days.count - 1].approvals.append(approval) }
            else { days.append((approval.day, [approval])) }
        }
        return days
    }

    /// "2026-11-25" for `date`, as the log writes days.
    public static func isoDay(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}
