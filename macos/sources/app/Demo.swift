import AutoApproverCore
import Foundation

/// `--demo <page>` opens the window on that page (`status`, `paused`, `activity`, `chats` or
/// `settings`), in light or, with `--dark`, in dark, with made-up chats and approvals. It
/// changes nothing: it starts no monitor, asks for no permission, sends no notification and
/// writes neither the log nor the settings. The README's screenshots are taken in it, so they
/// show no one's real work.
enum Demo {
    static let page: String? = CommandLine.arguments.firstIndex(of: "--demo").map { index in
        index + 1 < CommandLine.arguments.count ? CommandLine.arguments[index + 1] : "status"
    }
    static var on: Bool { page != nil }
    static let dark = CommandLine.arguments.contains("--dark")

    static var pane: Pane {
        switch page {
        case "activity": .activity
        case "chats": .chats
        case "settings": .settings
        default: .status
        }
    }

    /// The woodpecker's frame while the demo shows it still: just after a strike, with its bubble.
    static let frame = 22

    static let chats = [
        AppModel.Chat(title: "Add dark mode to the settings page", skipped: false, isOpen: true),
        AppModel.Chat(title: "Fix the flaky checkout test", skipped: false, isOpen: true),
        AppModel.Chat(title: "Migrate the API client to v2", skipped: false, isOpen: true),
        AppModel.Chat(title: "Draft the release notes", skipped: true, isOpen: true),
        AppModel.Chat(title: "Try a faster JSON parser", skipped: true, isOpen: false),
    ]

    /// A morning of approvals, newest first, and a few from the day before.
    static let approvals: [Approval] = {
        let today = Activity.isoDay(Date())
        let yesterday = Activity.isoDay(Date().addingTimeInterval(-86_400))
        let made: [(String, String, Bool, String, String)] = [
            (today, "11:48:12", false, "Add dark mode to the settings page", "Allow Claude to run npm test"),
            (today, "11:46:03", true, "Fix the flaky checkout test", "Allow Claude to run npx playwright test checkout"),
            (today, "11:31:40", false, "Add dark mode to the settings page", "Allow Claude to edit src/settings/Theme.tsx"),
            (today, "11:02:17", true, "Migrate the API client to v2", "Allow Claude to fetch api.github.com"),
            (today, "10:44:55", false, "Migrate the API client to v2", "Allow Claude to run git status"),
            (today, "10:12:09", false, "Fix the flaky checkout test", "Allow Claude to run npm run lint"),
            (yesterday, "18:20:31", true, "Draft the release notes", "Allow Claude to run git log --oneline v1.3.0..HEAD"),
            (yesterday, "17:05:48", false, "Add dark mode to the settings page", "Allow Claude to run npm run build"),
        ]
        return made.map { day, clock, banner, chat, request in
            Approval(time: "\(day) \(clock)", label: "Allow once", fromNotification: banner, locked: false,
                     chat: chat, request: request)
        }
    }()
}
