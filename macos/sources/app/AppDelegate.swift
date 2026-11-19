import AppKit
import ApplicationServices
import AutoApproverCore

final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    private let monitor = Monitor()
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    private let statusLine = NSMenuItem()
    private let detailLine = NSMenuItem()
    private let pauseItem = NSMenuItem()
    private let resumeItem = NSMenuItem()
    private let skipMenu = NSMenu()
    private var refreshTimer: Timer?

    func applicationDidFinishLaunching(_ notification: Notification) {
        log("🚀 \(Product.name) \(Settings.version) started [\(L10n.current)]")
        Notifier.shared.setup()
        Screen.observe()
        buildMenu()

        // Pressing buttons needs Accessibility: ask once at launch, then keep the icon honest.
        let prompt = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        if !AXIsProcessTrustedWithOptions(prompt) {
            log("⚠️  Accessibility not granted — System Settings → Privacy & Security → Accessibility")
        }
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 3, repeats: true) { [weak self] _ in self?.refreshMenu() }
        monitor.onStateChange = { [weak self] in DispatchQueue.main.async { self?.refreshMenu() } }
        monitor.start()

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            Notifier.shared.send(title: L10n.t(.running),
                                 body: L10n.t(AXIsProcessTrusted() ? .runningBody : .needsAccessBody))
        }
    }

    private func buildMenu() {
        statusItem.button?.toolTip = "\(Product.name) \(Settings.version) — \(Product.author)"

        let menu = NSMenu()
        menu.autoenablesItems = false
        menu.delegate = self

        menu.addItem(disabled("\(Product.name) \(Settings.version)"))
        let author = disabled("")
        author.attributedTitle = styled(L10n.t(.by), size: 11, color: .secondaryLabelColor)
        menu.addItem(author)
        menu.addItem(.separator())

        statusLine.isEnabled = false
        detailLine.isEnabled = false
        menu.addItem(statusLine)
        menu.addItem(detailLine)
        menu.addItem(.separator())

        resumeItem.title = "  " + L10n.t(.resume)
        resumeItem.action = #selector(resume)
        resumeItem.target = self
        menu.addItem(resumeItem)
        pauseItem.title = "  " + L10n.t(.pause)
        pauseItem.submenu = pauseMenu()
        menu.addItem(pauseItem)
        let skipItem = NSMenuItem(title: "  " + L10n.t(.skipChats), action: nil, keyEquivalent: "")
        skipMenu.delegate = self
        skipItem.submenu = skipMenu
        menu.addItem(skipItem)
        menu.addItem(item(L10n.t(.openLog), #selector(openLog)))
        menu.addItem(.separator())
        menu.addItem(item(L10n.t(.quit), #selector(quit), key: "q"))

        statusItem.menu = menu
        refreshMenu()
    }

    private func pauseMenu() -> NSMenu {
        let menu = NSMenu()
        for duration in Pause.durations {
            let title = duration.map { L10n.duration($0) } ?? L10n.t(.untilResume)
            let item = NSMenuItem(title: title, action: #selector(pause(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = duration
            if duration == nil { menu.addItem(.separator()) }
            menu.addItem(item)
        }
        return menu
    }

    func menuNeedsUpdate(_ menu: NSMenu) {
        guard menu === skipMenu else { return refreshMenu() }
        // The chats open now, and the skipped ones even when closed, so each can be undone.
        let skipped = Chats.skipped(fromFile: Settings.readSkippedChats())
        var titles = skipped
        for chat in monitor.openChats where !Chats.isSkipped(chat, titles) { titles.append(chat) }
        menu.removeAllItems()
        if titles.isEmpty { menu.addItem(withTitle: L10n.t(.noChats), action: nil, keyEquivalent: "").isEnabled = false }
        for title in titles.sorted(by: { $0.localizedStandardCompare($1) == .orderedAscending }) {
            let item = NSMenuItem(title: title, action: #selector(toggleSkip(_:)), keyEquivalent: "")
            item.target = self
            item.state = Chats.isSkipped(title, skipped) ? .on : .off
            menu.addItem(item)
        }
    }

    private func refreshMenu() {
        let on = monitor.active
        let trusted = AXIsProcessTrusted()
        statusItem.button?.image = MenuBarIcon.image(active: on && trusted)
        let status = on ? L10n.t(.statusOn) : monitor.resumeAt.map { L10n.pausedUntil($0) } ?? L10n.t(.statusOff)
        statusLine.attributedTitle = styled(status, size: 13, weight: .medium,
                                            color: on ? .systemGreen : .secondaryLabelColor)
        detailLine.attributedTitle = styled(L10n.t(trusted ? .detailOn : .detailNeedsAccess), size: 11,
                                            color: trusted ? .secondaryLabelColor : .systemOrange)
        resumeItem.isHidden = on
    }

    // Menu titles are indented two spaces, so text lines up under the status dot.
    private func item(_ title: String, _ action: Selector, key: String = "") -> NSMenuItem {
        let item = NSMenuItem(title: "  " + title, action: action, keyEquivalent: key)
        item.target = self
        return item
    }

    private func disabled(_ title: String) -> NSMenuItem {
        let item = NSMenuItem(title: "  " + title, action: nil, keyEquivalent: "")
        item.isEnabled = false
        return item
    }

    private func styled(_ text: String, size: CGFloat, weight: NSFont.Weight = .regular, color: NSColor) -> NSAttributedString {
        NSAttributedString(string: "  " + text,
                           attributes: [.foregroundColor: color, .font: NSFont.systemFont(ofSize: size, weight: weight)])
    }

    @objc private func pause(_ sender: NSMenuItem) { monitor.pause(for: sender.representedObject as? TimeInterval) }
    @objc private func resume() { monitor.resume() }
    @objc private func toggleSkip(_ sender: NSMenuItem) {
        Settings.toggleSkipped(sender.title)
        log(sender.state == .on ? "▶️ Approving \"\(sender.title)\" again" : "⏭ Skipping \"\(sender.title)\"")
    }
    @objc private func openLog() { NSWorkspace.shared.open(URL(fileURLWithPath: Settings.logPath)) }
    @objc private func quit() { NSApp.terminate(nil) }
}
