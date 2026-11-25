import AppKit
import ApplicationServices
import AutoApproverCore
import ServiceManagement
import SwiftUI

// MARK: - Model

/// What the window and the menu show, read again whenever the menu is refreshed.
final class AppModel: ObservableObject {
    struct Chat: Identifiable, Equatable {
        let title: String
        let skipped: Bool
        let isOpen: Bool
        var id: String { title }
    }

    let monitor: Monitor
    @Published private(set) var active = true
    @Published private(set) var resumeAt: Date?
    @Published private(set) var trusted = false
    @Published private(set) var chats: [Chat] = []
    @Published private(set) var approvals: [Approval] = []
    @Published var pane: Pane = .status
    /// Typed in the sidebar's search field; it filters the activity and the chats.
    /// Typed in the sidebar: the detail shows what matches across pages, chats and approvals.
    @Published var query = ""
    /// Whether any of the window is on screen: the woodpecker rests while it is not, since a
    /// closed window's views live on and would keep decoding frames.
    @Published var windowVisible = false

    init(monitor: Monitor) {
        self.monitor = monitor
        refresh()
    }

    var statusText: String {
        active ? L10n.t(.statusOn) : resumeAt.map { L10n.pausedUntil($0) } ?? L10n.t(.statusOff)
    }

    /// The status without the menu's leading dot, for places that draw their own.
    // Without Accessibility nothing is pressed, whatever the switch says.
    var statusTitle: String {
        trusted ? statusText.trimmingCharacters(in: CharacterSet(charactersIn: "●○ "))
            : "\(L10n.t(.accessibility)): \(L10n.t(.notGranted).lowercased())"
    }

    var statusColor: Color { !trusted ? .orange : active ? .green : .secondary }

    var approvedToday: Int {
        let today = Activity.isoDay(Date())
        return approvals.filter { $0.day == today }.count
    }

    func matches(_ text: String) -> Bool {
        let query = query.trimmingCharacters(in: .whitespaces)
        return query.isEmpty || text.range(of: query, options: [.caseInsensitive, .diacriticInsensitive]) != nil
    }

    func matches(_ approval: Approval) -> Bool {
        [approval.label, approval.chat ?? "", approval.request ?? "", L10n.day(approval.day)].contains(where: matches)
    }

    /// Call on the main thread.
    func refresh() {
        active = monitor.active
        resumeAt = monitor.resumeAt
        trusted = AXIsProcessTrusted()
        let open = monitor.openChats
        let skipped = Chats.skipped(fromFile: Settings.readSkippedChats())
        let listed = Chats.listed(open: open, skipped: skipped)
            .map { Chat(title: $0, skipped: Chats.isSkipped($0, skipped), isOpen: Chats.isSkipped($0, open)) }
        if listed != chats { chats = listed }
        let read = Activity.approvals(fromLog: Settings.readLogTail())
        if read != approvals { approvals = read }
    }

    func pause(for duration: TimeInterval?) { monitor.pause(for: duration); refresh() }
    func resume() { monitor.resume(); refresh() }
    func toggleSkip(_ chat: Chat) {
        Settings.toggleSkipped(chat.title)
        log(chat.skipped ? "▶️ Approving \"\(chat.title)\" again" : "⏭ Skipping \"\(chat.title)\"")
        refresh()
    }
}

enum Pane: CaseIterable, Identifiable {
    case status, activity, chats, settings
    var id: Self { self }

    var title: String {
        switch self {
        case .status: L10n.t(.paneStatus)
        case .activity: L10n.t(.paneActivity)
        case .chats: L10n.t(.paneChats)
        case .settings: L10n.t(.paneSettings)
        }
    }

    var symbol: String {
        switch self {
        case .status: "checkmark.seal"
        case .activity: "clock.arrow.circlepath"
        case .chats: "bubble.left.and.bubble.right"
        case .settings: "gearshape"
        }
    }
}

// MARK: - Window

/// The window: a sidebar beside the selected pane, in a split view controller, so macOS 26
/// draws the sidebar as a Liquid Glass pane that reaches the top, with the window controls inside.
final class MainWindow: NSWindow, NSToolbarDelegate {
    private let split = NSSplitViewController()

    init(model: AppModel) {
        let sidebar = Self.pane(SidebarView(model: model))
        let detail = Self.pane(DetailView(model: model))

        let side = NSSplitViewItem(sidebarWithViewController: sidebar)
        side.minimumThickness = 230
        side.maximumThickness = 230   // always its narrowest width, as in the App Store
        side.canCollapse = false
        split.addSplitViewItem(side)
        let content = NSSplitViewItem(viewController: detail)
        content.minimumThickness = 480
        split.addSplitViewItem(content)

        super.init(contentRect: NSRect(x: 0, y: 0, width: 1080, height: 720),
                   styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
                   backing: .buffered, defer: false)
        contentViewController = split
        title = Product.name
        titleVisibility = .hidden
        titlebarAppearsTransparent = true
        let toolbar = NSToolbar(identifier: "Main")
        toolbar.delegate = self
        self.toolbar = toolbar
        toolbarStyle = .unifiedCompact
        setContentSize(NSSize(width: 1080, height: 720))
        minSize = NSSize(width: 760, height: 560)
        isReleasedWhenClosed = false
        center()
        setFrameAutosaveName("Main")
        NotificationCenter.default.addObserver(forName: NSWindow.didChangeOcclusionStateNotification, object: self,
                                               queue: .main) { [weak self, weak model] _ in
            guard let self else { return }
            model?.windowVisible = self.occlusionState.contains(.visible)
        }
    }

    /// A pane whose SwiftUI content follows the pane's frame and never sets it: a hosting
    /// controller's view sized itself to its content, and the Status grid held the window wide.
    private static func pane(_ root: some View) -> NSViewController {
        let host = NSHostingView(rootView: root)
        host.sizingOptions = []
        host.translatesAutoresizingMaskIntoConstraints = true
        host.autoresizingMask = [.width, .height]
        let controller = NSViewController()
        controller.view = NSView(frame: NSRect(x: 0, y: 0, width: 600, height: 600))
        host.frame = controller.view.bounds
        controller.view.addSubview(host)
        return controller
    }

    // The toolbar holds only the separator that ties it to the sidebar, so the sidebar runs to the top.
    func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] { [.sidebarTrackingSeparator] }
    func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] { [.sidebarTrackingSeparator] }
    func toolbar(_ toolbar: NSToolbar, itemForItemIdentifier identifier: NSToolbarItem.Identifier,
                 willBeInsertedIntoToolbar flag: Bool) -> NSToolbarItem? {
        guard identifier == .sidebarTrackingSeparator else { return nil }
        return NSTrackingSeparatorToolbarItem(identifier: identifier, splitView: split.splitView, dividerIndex: 0)
    }
}

// MARK: - Style

/// The brand's coral, as on the icon and the README banner.
let coral = Color(red: 0.98, green: 0.384, blue: 0.157)

/// Badge gradients, one per meaning, each two neighbouring hues so none clashes.
enum Tone {
    static let success = [Color(red: 0.30, green: 0.82, blue: 0.47), Color(red: 0.13, green: 0.64, blue: 0.40)]
    static let chats = [Color(red: 0.33, green: 0.60, blue: 1.00), Color(red: 0.31, green: 0.40, blue: 0.96)]
    static let access = [Color(red: 0.66, green: 0.52, blue: 1.00), Color(red: 0.47, green: 0.34, blue: 0.92)]
    static let warning = [Color(red: 1.00, green: 0.55, blue: 0.25), Color(red: 0.93, green: 0.30, blue: 0.24)]
    static let awake = [Color(red: 1.00, green: 0.76, blue: 0.28), Color(red: 0.97, green: 0.53, blue: 0.16)]
    static let notification = [Color(red: 1.00, green: 0.45, blue: 0.40), Color(red: 0.90, green: 0.24, blue: 0.36)]
    static let window = [Color(red: 0.98, green: 0.52, blue: 0.24), coral]
    static let muted = [Color(red: 0.62, green: 0.64, blue: 0.68), Color(red: 0.45, green: 0.47, blue: 0.52)]
}
let hero = [Color(red: 0.86, green: 0.2, blue: 0.33), coral, Color(red: 1.0, green: 0.55, blue: 0.22)]   // red to orange

extension View {
    func cardBackground() -> some View {
        background(RoundedRectangle(cornerRadius: 22, style: .continuous).fill(Color.primary.opacity(0.045)))
    }
}

/// A capsule button for the hero card's gradient: white and filled, or white glass.
/// A capsule on the hero: brighter on hover, pressed in while held, faded when disabled.
struct PillButtonStyle: ButtonStyle {
    var filled = false

    func makeBody(configuration: Configuration) -> some View { Pill(configuration: configuration, filled: filled) }

    private struct Pill: View {
        let configuration: Configuration
        let filled: Bool
        @State private var hovering = false
        @Environment(\.isEnabled) private var enabled

        var body: some View {
            configuration.label
                .font(.headline)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .foregroundStyle(filled ? coral : .white)
                .background(Capsule().fill(filled ? Color.white.opacity(hovering ? 0.9 : 1)
                                                  : Color.white.opacity(hovering ? 0.32 : 0.22)))
                .overlay(Capsule().strokeBorder(Color.white.opacity(filled ? 0 : 0.5), lineWidth: 1))
                // Lifts a white pill off a light backdrop.
                .shadow(color: .black.opacity(filled ? 0.12 : 0), radius: 6, y: 2)
                .scaleEffect(configuration.isPressed ? 0.96 : 1)
                .opacity(enabled ? 1 : 0.5)
                .contentShape(Capsule())
                .onHover { hovering = $0 }
                .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
                .animation(.easeOut(duration: 0.12), value: hovering)
        }
    }
}

/// A coloured rounded square with a symbol, as an app icon stands beside a row.
struct Badge: View {
    let symbol: String
    let colors: [Color]
    var size: CGFloat = 40

    var body: some View {
        Image(systemName: symbol)
            .font(.system(size: size * 0.45, weight: .semibold))
            .foregroundStyle(.white)
            .frame(width: size, height: size)
            .background(RoundedRectangle(cornerRadius: size * 0.27, style: .continuous)
                .fill(LinearGradient(colors: colors, startPoint: .top, endPoint: .bottom)))
            .accessibilityHidden(true)
    }
}

struct PaneScroll<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                Text(title)
                    .font(.system(size: 28, weight: .bold))
                    .accessibilityAddTraits(.isHeader)
                content
            }
            .padding(.horizontal, 28)
            .padding(.top, 20)
            .padding(.bottom, 44)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

struct SectionTitle: View {
    let title: String
    var action: (label: String, run: () -> Void)?

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title).font(.title2.weight(.bold)).accessibilityAddTraits(.isHeader)
            Spacer()
            if let action { Button(action.label, action: action.run).buttonStyle(.link).font(.title3) }
        }
    }
}

// MARK: - Sidebar

/// A sidebar row: a light plate when selected, fainter on hover, darker while pressed.
private struct SidebarRowStyle: ButtonStyle {
    let selected: Bool
    @State private var hovering = false

    func makeBody(configuration: Configuration) -> some View {
        let plate = configuration.isPressed ? 0.1 : selected ? 0.06 : hovering ? 0.035 : 0
        configuration.label
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(Color.primary.opacity(plate)))
            .contentShape(Rectangle())
            .onHover { hovering = $0 }
            .animation(.easeOut(duration: 0.12), value: plate)
    }
}

private struct SidebarView: View {
    @ObservedObject var model: AppModel

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass").foregroundStyle(.secondary).accessibilityHidden(true)
                TextField(L10n.t(.search), text: $model.query)
                    .textFieldStyle(.plain)
                    .font(.system(size: 15))
                if !model.query.isEmpty {
                    Button { model.query = "" } label: { Image(systemName: "xmark.circle.fill") }
                        .buttonStyle(.plain)
                        .foregroundStyle(.secondary)
                        .accessibilityLabel(L10n.t(.close))
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background(Capsule().fill(Color.primary.opacity(0.07)))
            .padding(.horizontal, 12)
            .padding(.top, 8)
            .padding(.bottom, 10)

            // As in the App Store: outline symbols, and the selected row in the accent colour on
            // a light plate rather than a filled highlight.
            VStack(spacing: 4) {
                ForEach(Pane.allCases.filter { model.matches($0.title) }) { pane in
                    let selected = model.pane == pane && model.query.isEmpty
                    Button { model.pane = pane; model.query = "" } label: {
                        HStack(spacing: 12) {
                            Image(systemName: pane.symbol)
                                .font(.system(size: 17))
                                .frame(width: 24)
                                .accessibilityHidden(true)
                            Text(pane.title).font(.system(size: 15))
                            Spacer(minLength: 0)
                        }
                        .foregroundStyle(selected ? Color.accentColor : .primary)
                    }
                    .buttonStyle(SidebarRowStyle(selected: selected))
                    .accessibilityAddTraits(selected ? .isSelected : [])
                }
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 10)

            HStack(spacing: 12) {
                Image(nsImage: NSApp.applicationIconImage)
                    .resizable()
                    .frame(width: 40, height: 40)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Auto Approver").font(.headline)
                    HStack(spacing: 5) {
                        Circle().fill(model.statusColor).frame(width: 7, height: 7).accessibilityHidden(true)
                        Text(model.statusTitle).font(.caption).foregroundStyle(.secondary).lineLimit(1)
                    }
                }
                Spacer(minLength: 0)
            }
            .padding(16)
            .accessibilityElement(children: .combine)
        }
    }
}

// MARK: - Panes

private struct DetailView: View {
    @ObservedObject var model: AppModel

    var body: some View {
        if !model.query.trimmingCharacters(in: .whitespaces).isEmpty { SearchPane(model: model) } else {
        switch model.pane {
        case .status: StatusPane(model: model)
        case .activity: ActivityPane(model: model)
        case .chats: ChatsPane(model: model)
        case .settings: SettingsPane()
        }
        }
    }
}

private struct StatusPane: View {
    @ObservedObject var model: AppModel

    var body: some View {
        GeometryReader { pane in
            PaneScroll(title: Pane.status.title) {
                HeroCard(model: model, width: pane.size.width - 56)
                // Columns from the pane's width: an adaptive grid in a scroll view held the pane four cards wide.
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 18),
                                         count: max(1, min(4, Int((pane.size.width - 56 + 18) / 218)))), spacing: 18) {
                    StatCard(eyebrow: L10n.t(.approvedToday), value: "\(model.approvedToday)",
                             caption: model.approvals.first.map { "\(L10n.t(.lastApproval)): \(L10n.day($0.day)), \($0.clock)" }
                                ?? L10n.t(.noneYet),
                             badge: Badge(symbol: "checkmark.seal.fill", colors: Tone.success))
                    StatCard(eyebrow: L10n.t(.openChats), value: "\(model.chats.filter(\.isOpen).count)",
                             caption: "\(L10n.t(.skippedChats)): \(model.chats.filter(\.skipped).count)",
                             badge: Badge(symbol: "bubble.left.and.bubble.right.fill", colors: Tone.chats)) {
                        Button(L10n.t(.manage)) { model.pane = .chats }.buttonStyle(.link)
                    }
                    StatCard(eyebrow: L10n.t(.accessibility), value: L10n.t(model.trusted ? .granted : .notGranted),
                             caption: L10n.t(model.trusted ? .detailOn : .detailNeedsAccess)
                                .trimmingCharacters(in: CharacterSet(charactersIn: "⚠️ ")),
                             badge: Badge(symbol: "hand.raised.fill", colors: model.trusted ? Tone.access : Tone.warning))
                    StatCard(eyebrow: L10n.t(.keepAwake), value: model.active ? "☕️" : "💤",
                             caption: L10n.t(.keepAwakeBody),
                             badge: Badge(symbol: "cup.and.saucer.fill", colors: Tone.awake))
                }
                SectionTitle(title: L10n.t(.recent), action: model.approvals.isEmpty ? nil : (L10n.t(.showAll), { model.pane = .activity }))
                ApprovalList(approvals: Array(model.approvals.prefix(5)), showsDay: true)
            }
        }
    }
}

private struct HeroCard: View {
    @ObservedObject var model: AppModel
    let width: CGFloat

    var body: some View {
        // The artwork shrinks, then goes, as the pane narrows; the text wraps and the card grows.
        let artwork: CGFloat = width > 820 ? 380 : width > 620 ? 260 : 0
        let inset: CGFloat = width > 560 ? 36 : 24
        layout(artwork: artwork)
            .padding(.horizontal, inset)
            .padding(.vertical, 28)
            .frame(maxWidth: .infinity, minHeight: 260)
            // The scene is a background, so its size is never the card's.
            .background {
                if model.active {
                    KeyScene(artwork: artwork, inset: inset, animates: model.windowVisible)
                } else {
                    WoodlandScene(artwork: artwork, inset: inset)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
            .shadow(color: .black.opacity(0.12), radius: 24, y: 12)
    }

    @ViewBuilder private var buttons: some View {
        if !model.trusted {
            Button(L10n.t(.openAccessibility)) {
                NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!)
            }
            .buttonStyle(PillButtonStyle(filled: true))
        }
        if model.active {
            Menu {
                ForEach(Pause.durations, id: \.self) { duration in
                    if duration == nil { Divider() }
                    Button(L10n.pauseLength(duration)) { model.pause(for: duration) }
                }
            } label: {
                Label(L10n.t(.pause), systemImage: "pause.fill")
            }
            .menuStyle(.button)
            .buttonStyle(PillButtonStyle(filled: true))
            .fixedSize()
        } else {
            Button { model.resume() } label: { Label(L10n.t(.resume), systemImage: "play.fill") }
                .buttonStyle(PillButtonStyle(filled: true))
        }
    }

    private func layout(artwork size: CGFloat) -> some View {
        HStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Claude Code".uppercased())
                        .font(.headline)
                        .kerning(1)
                        .foregroundStyle(Color.black.opacity(0.55))
                    Text(model.statusTitle)
                        .font(.system(size: 40, weight: .medium))
                        .foregroundStyle(Color.black.opacity(0.85))
                        .lineLimit(2)
                        .minimumScaleFactor(0.7)
                    Text(L10n.t(model.trusted ? .runningBody : .needsAccessBody))
                        .font(.title3)
                        .foregroundStyle(Color.black.opacity(0.6))
                        .fixedSize(horizontal: false, vertical: true)
                    // Side by side while they fit, stacked when the pane is narrow.
                    ViewThatFits(in: .horizontal) {
                        HStack(spacing: 12) { buttons }
                        VStack(alignment: .leading, spacing: 10) { buttons }
                    }
                    .padding(.top, 8)
                }
                .frame(maxWidth: 520, alignment: .leading)
                .frame(maxWidth: .infinity, alignment: .leading)
                if size > 0 {
                    // Room for the woodpecker, which the card's background draws.
                    Color.clear.frame(width: size, height: size * 0.8)
                }
        }
    }
}

struct StatCard<Accessory: View>: View {
    let eyebrow: String
    let value: String
    let caption: String
    let badge: Badge
    @ViewBuilder let accessory: Accessory

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                badge
                Spacer()
                accessory
            }
            .padding(.bottom, 6)
            Text(eyebrow.uppercased())
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.system(size: 22, weight: .bold))
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Text(caption)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(22)
        .frame(maxWidth: .infinity, minHeight: 200, alignment: .topLeading)
        .cardBackground()
        .accessibilityElement(children: .combine)
    }
}

extension StatCard where Accessory == EmptyView {
    init(eyebrow: String, value: String, caption: String, badge: Badge) {
        self.init(eyebrow: eyebrow, value: value, caption: caption, badge: badge) { EmptyView() }
    }
}

struct EmptyState: View {
    let symbol: String
    let text: String

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: symbol).font(.system(size: 46)).foregroundStyle(.tertiary).accessibilityHidden(true)
            Text(text).font(.title3).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 56)
        .cardBackground()
    }
}

private struct SettingsPane: View {
    @State private var labels = Settings.readLabels() ?? ""
    @State private var saved = Settings.readLabels() ?? ""
    @State private var atLogin = SMAppService.mainApp.status == .enabled
    private let builtIn = Labels.wanted(fromFile: nil).map { $0.joined(separator: " ") }.sorted()

    var body: some View {
        PaneScroll(title: Pane.settings.title) {
            VStack(alignment: .leading, spacing: 12) {
                SectionTitle(title: L10n.t(.general))
                VStack(spacing: 0) {
                    row(Badge(symbol: "power", colors: Tone.success, size: 36), L10n.t(.launchAtLogin)) {
                        Toggle(L10n.t(.launchAtLogin), isOn: Binding(get: { atLogin }, set: setOpenAtLogin))
                            .toggleStyle(.switch)
                            .labelsHidden()
                    }
                    Divider().padding(.leading, 50)
                    row(Badge(symbol: "cup.and.saucer.fill", colors: Tone.awake, size: 36), L10n.t(.keepAwake),
                        detail: L10n.t(.keepAwakeBody)) { EmptyView() }
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 6)
                .cardBackground()
            }

            VStack(alignment: .leading, spacing: 12) {
                SectionTitle(title: L10n.t(.labelsTitle))
                VStack(alignment: .leading, spacing: 14) {
                    Text(L10n.t(.labelsHint)).foregroundStyle(.secondary)
                    TextEditor(text: $labels)
                        .font(.body.monospaced())
                        .scrollContentBackground(.hidden)
                        .padding(8)
                        .frame(minHeight: 110)
                        .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color(nsColor: .textBackgroundColor)))
                        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).strokeBorder(Color.primary.opacity(0.12)))
                        .accessibilityLabel(L10n.t(.labelsTitle))
                    HStack {
                        Text(L10n.t(.builtInLabels)).font(.headline)
                        Spacer()
                        Button(L10n.t(.save)) { if Settings.writeLabels(labels) { saved = labels } }
                            .buttonStyle(.borderedProminent)
                            .disabled(labels == saved)
                            .keyboardShortcut("s")
                    }
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), alignment: .leading)], alignment: .leading, spacing: 8) {
                        ForEach(builtIn, id: \.self) { label in
                            Text(label)
                                .font(.callout)
                                .lineLimit(1)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(Capsule().fill(coral.opacity(0.12)))
                        }
                    }
                }
                .padding(20)
                .cardBackground()
            }

            VStack(alignment: .leading, spacing: 12) {
                SectionTitle(title: L10n.t(.files))
                VStack(spacing: 0) {
                    row(Badge(symbol: "doc.text.fill", colors: Tone.muted, size: 36), "ClaudeCodeAutoApprover.log",
                        detail: (Settings.logPath as NSString).abbreviatingWithTildeInPath) {
                        HStack {
                            Button(L10n.t(.openLog)) { NSWorkspace.shared.open(URL(fileURLWithPath: Settings.logPath)) }
                            Button(L10n.t(.showInFinder)) {
                                NSWorkspace.shared.activateFileViewerSelecting([URL(fileURLWithPath: Settings.logPath)])
                            }
                        }
                    }
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 6)
                .cardBackground()
            }

            VStack(alignment: .leading, spacing: 12) {
                SectionTitle(title: L10n.t(.about))
                HStack(spacing: 18) {
                    Image(nsImage: NSApp.applicationIconImage).resizable().frame(width: 72, height: 72).accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(Product.name).font(.title3.weight(.semibold))
                        Text("\(Settings.version) · \(L10n.t(.by))").foregroundStyle(.secondary)
                        HStack(spacing: 16) {
                            Link("GitHub", destination: Product.repository)
                            Link("\(L10n.t(.license)): MIT", destination: Product.repository.appendingPathComponent("blob/main/LICENSE"))
                        }
                        .padding(.top, 4)
                    }
                    Spacer()
                }
                .padding(20)
                .cardBackground()
            }
        }
    }

    private func row<Trailing: View>(_ badge: Badge, _ title: String, detail: String? = nil,
                                     @ViewBuilder trailing: () -> Trailing) -> some View {
        HStack(spacing: 14) {
            badge
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.body.weight(.semibold))
                if let detail { Text(detail).font(.callout).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true) }
            }
            Spacer()
            trailing()
        }
        .padding(.vertical, 11)
    }

    private func setOpenAtLogin(_ on: Bool) {
        do {
            if on { try SMAppService.mainApp.register() } else { try SMAppService.mainApp.unregister() }
            log(on ? "🔑 Opens at login" : "🔑 No longer opens at login")
        } catch {
            log("❌ Could not change opening at login: \(error.localizedDescription)")
        }
        atLogin = SMAppService.mainApp.status == .enabled
    }
}
