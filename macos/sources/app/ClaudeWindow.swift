import ApplicationServices
import AutoApproverCore

/// The permission dialog in the Claude desktop app's window, for the session on screen.
enum ClaudeWindow {
    static let bundleId = "com.anthropic.claudefordesktop"
    private static var known: Set<String> = []
    private static var lastWaiting = ""
    private static var loggedSkips: Set<String> = []
    /// Titles of the chats open in the window or active in its sidebar, from the last full walk.
    private(set) static var openChats: [String] = []

    /// Presses the first button in the Claude window whose label is wanted, outside a
    /// skipped chat. Returns what was pressed, or nil when no such button is on screen.
    static func pressAllow(_ wanted: Set<[String]>, skipping skipped: [String]) -> Pressed? {
        guard let app = AXNode.application(bundleId) else { return nil }
        // Electron builds its accessibility tree only once an assistive client asks for it.
        AXUIElementSetAttributeValue(app, "AXManualAccessibility" as CFString, kCFBooleanTrue)

        var visited = 0
        var fresh: [String] = []
        var waiting: AXNode?
        var chats: [String] = []
        var active: [String] = []
        var rows: Set<String> = []   // chats in the sidebar, so a look-alike button is not taken for one

        // The walk is in document order and each chat's header precedes its content, so a
        // button belongs to the chat whose header was seen last. A sidebar row's menu
        // button stands alone; a header's has the chat's icon and heading beside it.
        func find(_ element: AXUIElement, _ depth: Int, siblings: Int) -> AXNode? {
            visited += 1
            guard depth < 80, visited < 30_000, let node = AXNode(element) else { return nil }
            if waiting == nil, Labels.isWaiting(node.text) { waiting = node }
            if node.role == kAXPopUpButtonRole, let title = Chats.title(fromMenuButton: node.detail) {
                if siblings > 1 { chats.append(title) } else { rows.insert(title) }
            }
            // A sidebar row: the chat's button holds its title and, last, its status.
            if node.isButton, node.children.count == 2, let status = AXNode(node.children[1]),
               let title = Chats.activeTitle(rowLabel: node.label, status: status.detail) {
                active.append(title)
            }
            if node.isButton {
                if Labels.matches(node.label, wanted) {
                    guard Chats.isSkipped(chats.last, skipped) else { return node }
                    let chat = chats.last ?? ""
                    if loggedSkips.insert(chat).inserted { log("⏭ Left for you: a prompt in \"\(chat)\"") }
                    return nil
                }
                // Short labels new to this run are logged: a dialog's buttons show up here.
                let label = node.label
                if label.count <= 30, Labels.words(label).count <= 4, known.insert(label).inserted { fresh.append(label) }
            }
            for child in node.children {
                if let hit = find(child, depth + 1, siblings: node.children.count) { return hit }
            }
            return nil
        }

        // A plain loop, not lazy.compactMap(...).first: that runs the walk twice, and the
        // second walk, past the visit budget the first one spent, finds nothing.
        var button: AXNode?
        for window in AXNode.windows(of: app) {
            button = find(window, 0, siblings: 1)
            if button != nil { break }
        }
        if button == nil { openChats = chats + active.filter { rows.contains($0) && !Chats.isSkipped($0, chats) }; if chats.isEmpty { loggedSkips.removeAll() } }
        if !fresh.isEmpty { log("🆕 New buttons: \(fresh.joined(separator: " · "))") }
        if known.count > 3000 { known.removeAll() }

        guard let button else {
            logWaiting(waiting)
            return nil
        }
        // Read before pressing: the dialog closes with the press.
        let asked = request(around: button)
        let r = button.perform(kAXPressAction)
        guard r == .success else {
            log("❌ Pressing \"\(button.label)\" failed (AXError \(r.rawValue))")
            return nil
        }
        return Pressed(label: button.label, chat: chats.last, request: asked)
    }

    /// The dialog's own text: the first sentences in the nearest ancestor that holds any
    /// besides buttons. Best effort, within a small budget.
    private static func request(around button: AXNode) -> String? {
        var node = button.parent
        for _ in 0..<6 {
            guard let current = node else { return nil }
            var texts: [String] = []
            var budget = 300
            func collect(_ element: AXUIElement, _ depth: Int) {
                budget -= 1
                guard budget > 0, depth < 8, texts.count < 3, let child = AXNode(element) else { return }
                if child.role == kAXStaticTextRole, child.text.count >= 8 { texts.append(child.text) }
                if !child.isButton { child.children.forEach { collect($0, depth + 1) } }
            }
            current.children.forEach { collect($0, 0) }
            if !texts.isEmpty { return texts.joined(separator: " ") }
            node = current.parent
        }
        return nil
    }

    /// A session waits and no dialog is on screen: it is another session. Logged, not
    /// clicked, until its layout is known (the label may head a sidebar section).
    private static func logWaiting(_ waiting: AXNode?) {
        guard let waiting else { lastWaiting = ""; return }
        var description = waiting.summary
        if let parent = waiting.parent {
            let siblings = parent.children.prefix(12).compactMap(AXNode.init).map(\.summary)
            description += " · parent " + parent.summary + " → " + siblings.joined(separator: ", ")
        }
        if description != lastWaiting { log("⏳ A session is waiting, no dialog on screen: \(description)") }
        lastWaiting = description
    }
}
