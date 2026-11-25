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
    private lazy var model = AppModel(monitor: monitor)
    private lazy var window = MainWindow(model: model)

    func applicationDidFinishLaunching(_ notification: Notification) {
        log("🚀 \(Product.name) \(Settings.version) started [\(L10n.current)]")
        Notifier.shared.setup()
        Screen.observe()
        // A new status item takes the leftmost place, which a notch hides on a full menu bar;
        // until the person drags it elsewhere, it starts next to the clock instead.
        UserDefaults.standard.register(defaults: ["NSStatusItem Preferred Position Item-0": 120])
        buildMainMenu()
        buildMenu()

        // Pressing buttons needs Accessibility: ask once at launch, then keep the icon honest.
        let prompt = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        if !AXIsProcessTrustedWithOptions(prompt) {
            log("⚠️  Accessibility not granted — System Settings → Privacy & Security → Accessibility")
        }
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 3, repeats: true) { [weak self] _ in self?.refreshMenu() }
        monitor.onStateChange = { [weak self] in DispatchQueue.main.async { self?.refreshMenu() } }
        monitor.start()
        showWindow()

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            Notifier.shared.send(title: L10n.t(.running),
                                 body: L10n.t(AXIsProcessTrusted() ? .runningBody : .needsAccessBody))
        }
    }

    // The window is opened at launch, from the Dock and from the menu bar; closing it leaves
    // the app running in the menu bar.
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag { showWindow() }
        return true
    }

    @objc private func showWindow() {
        model.refresh()
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
        // Nothing focused: the search field would otherwise take every key typed at the window.
        window.makeFirstResponder(nil)
    }

    /// The app's own menus, for its window: Quit, the editing keys its text field needs, Close.
    private func buildMainMenu() {
        let main = NSMenu()
        func add(_ title: String, _ items: [NSMenuItem]) {
            let menu = NSMenu(title: title)
            items.forEach(menu.addItem)
            let host = NSMenuItem(title: title, action: nil, keyEquivalent: "")
            host.submenu = menu
            main.addItem(host)
        }
        func key(_ title: String, _ action: Selector, _ key: String) -> NSMenuItem {
            NSMenuItem(title: title, action: action, keyEquivalent: key)
        }
        add(Product.name, [key(L10n.t(.openWindow), #selector(showWindow), "0"), .separator(),
                           key(L10n.t(.hide), #selector(NSApplication.hide(_:)), "h"),
                           key(L10n.t(.quit), #selector(NSApplication.terminate(_:)), "q")])
        main.items.first?.submenu?.items.first?.target = self
        add(L10n.t(.edit), [key(L10n.t(.cut), #selector(NSText.cut(_:)), "x"),
                            key(L10n.t(.copy), #selector(NSText.copy(_:)), "c"),
                            key(L10n.t(.paste), #selector(NSText.paste(_:)), "v"),
                            key(L10n.t(.selectAll), #selector(NSText.selectAll(_:)), "a")])
        add(L10n.t(.window), [key(L10n.t(.minimize), #selector(NSWindow.performMiniaturize(_:)), "m"),
                              key(L10n.t(.close), #selector(NSWindow.performClose(_:)), "w")])
        NSApp.mainMenu = main
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
        menu.addItem(item(L10n.t(.openWindow), #selector(showWindow)))
        menu.addItem(item(L10n.t(.openLog), #selector(openLog)))
        menu.addItem(item("GitHub", #selector(openRepository)))
        menu.addItem(.separator())
        menu.addItem(item(L10n.t(.quit), #selector(quit), key: "q"))

        statusItem.menu = menu
        refreshMenu()
    }

    private func pauseMenu() -> NSMenu {
        let menu = NSMenu()
        for duration in Pause.durations {
            let item = NSMenuItem(title: L10n.pauseLength(duration), action: #selector(pause(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = duration
            if duration == nil { menu.addItem(.separator()) }
            menu.addItem(item)
        }
        return menu
    }

    func menuNeedsUpdate(_ menu: NSMenu) {
        guard menu === skipMenu else { return refreshMenu() }
        model.refresh()
        menu.removeAllItems()
        if model.chats.isEmpty { menu.addItem(withTitle: L10n.t(.noChats), action: nil, keyEquivalent: "").isEnabled = false }
        for chat in model.chats {
            let item = NSMenuItem(title: chat.title, action: #selector(toggleSkip(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = chat
            item.state = chat.skipped ? .on : .off
            menu.addItem(item)
        }
    }

    private func refreshMenu() {
        model.refresh()
        let on = model.active
        let trusted = model.trusted
        statusItem.button?.image = MenuBarIcon.image(active: on && trusted)
        statusLine.attributedTitle = styled(model.statusText, size: 13, weight: .medium,
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

    @objc private func pause(_ sender: NSMenuItem) { model.pause(for: sender.representedObject as? TimeInterval) }
    @objc private func resume() { model.resume() }
    @objc private func toggleSkip(_ sender: NSMenuItem) {
        if let chat = sender.representedObject as? AppModel.Chat { model.toggleSkip(chat) }
    }
    @objc private func openLog() { NSWorkspace.shared.open(URL(fileURLWithPath: Settings.logPath)) }
    @objc private func openRepository() { NSWorkspace.shared.open(Product.repository) }
    @objc private func quit() { NSApp.terminate(nil) }
}
