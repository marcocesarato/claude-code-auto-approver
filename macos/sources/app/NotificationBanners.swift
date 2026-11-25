import ApplicationServices
import AutoApproverCore

/// The Claude app raises each permission request as a notification too ("Allow Claude to
/// run …?"): a request from a session not on screen exists only there.
enum NotificationBanners {
    static let bundleId = "com.apple.notificationcenterui"
    private static var known: Set<String> = []
    private static var steps: [String: Int] = [:]   // banner text -> fallbacks already tried

    private struct Item {
        let node: AXNode
        let actions: [String]

        func action(_ name: String) -> String? {
            actions.first { label(ofAction: $0).lowercased() == name }
        }
    }

    /// A custom action is named "Name:<label>\nTarget:…"; a standard one is its own name.
    private static func label(ofAction a: String) -> String {
        a.hasPrefix("Name:") ? String(a.dropFirst(5).prefix { $0 != "\n" }) : a
    }

    /// Every element under `root`, root first, bounded.
    private static func subtree(_ root: AXUIElement, limit: Int = 400) -> [Item] {
        var out: [Item] = [], stack = [root]
        while let element = stack.popLast(), out.count < limit {
            guard let node = AXNode(element) else { continue }
            out.append(Item(node: node, actions: node.actions))
            stack.append(contentsOf: node.children.reversed())
        }
        return out
    }

    /// Answers a Claude permission banner. Returns the label used when one was allowed.
    static func pressAction(_ wanted: Set<[String]>, skipping skipped: [String]) -> Pressed? {
        guard let center = AXNode.application(bundleId) else { return nil }
        let all = subtree(center, limit: 3000)
        for a in all.flatMap(\.actions) where a.hasPrefix("Name:") {
            if known.insert(label(ofAction: a)).inserted { log("🆕 Notification action: \(label(ofAction: a))") }
        }

        // A banner is the element offering "Show Details"; its text holds the request.
        for banner in all where banner.action("show details") != nil {
            let items = subtree(banner.node.element)
            let text = items.map(\.node.text).joined(separator: " ")
            guard text.lowercased().contains(Labels.permissionBanner) else { continue }
            let key = String(text.prefix(200))
            if steps[key] == nil { log("🔔 Permission notification: \(text.prefix(160))") }
            // A skipped chat's request is neither answered nor opened.
            if Chats.bannerIsSkipped(text, skipped) {
                if steps[key] == nil { log("⏭ Left for you: a notification from a skipped chat") }
                steps[key] = -1
                continue
            }

            // The action itself, offered as a custom action or as a button.
            for item in items {
                for a in item.actions where Labels.matches(label(ofAction: a), wanted) {
                    if item.node.perform(a) == .success { return pressed("\(label(ofAction: a)) (notification)", text) }
                }
                if item.node.isButton, Labels.matches(item.node.text, wanted),
                   item.node.perform(kAXPressAction) == .success {
                    return pressed("\(item.node.text) (notification)", text)
                }
            }

            // Not offered: expand the banner to reveal its actions, and failing that open
            // the session, where the dialog in the window is answered on the next tick.
            let step = steps[key] ?? 0
            steps[key] = step + 1
            if steps.count > 200 { steps.removeAll() }
            switch step {
            case 0:
                if let a = banner.action("show details") {
                    log("🔔 Expanding the notification (AXError \(banner.node.perform(a).rawValue))")
                }
            case 1:
                let r = banner.node.perform(kAXPressAction)
                let offered = items.flatMap(\.actions).map(label(ofAction:)).joined(separator: " · ")
                log("🔔 Opening the session from the notification (AXError \(r.rawValue)); actions: \(offered)")
            default: break
            }
            return nil
        }
        return nil
    }

    private static func pressed(_ label: String, _ banner: String) -> Pressed {
        let read = Activity.bannerRequest(banner)
        return Pressed(label: label, chat: read.chat, request: read.request)
    }
}
