import AppKit
import AutoApproverCore
import SwiftUI

/// What the sidebar's search finds: the pages by name, the chats by title and the approvals
/// by label, chat, request or day.
struct SearchPane: View {
    @ObservedObject var model: AppModel

    var body: some View {
        let pages = Pane.allCases.filter { model.matches($0.title) }
        let chats = model.chats.filter { model.matches($0.title) }
        let approvals = model.approvals.filter(model.matches)
        PaneScroll(title: L10n.t(.search)) {
            if pages.isEmpty, chats.isEmpty, approvals.isEmpty {
                EmptyState(symbol: "magnifyingglass", text: L10n.t(.noResults))
            }
            if !pages.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    SectionTitle(title: L10n.t(.pages))
                    rows(pages) { pane in
                        Button { model.pane = pane; model.query = "" } label: {
                            HStack(spacing: 14) {
                                Badge(symbol: pane.symbol, colors: Tone.window, size: 36)
                                Text(pane.title).font(.body.weight(.semibold))
                                Spacer()
                                Image(systemName: "chevron.right").foregroundStyle(.tertiary).accessibilityHidden(true)
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            if !chats.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    SectionTitle(title: Pane.chats.title)
                    rows(chats) { chat in
                        HStack(spacing: 14) {
                            Badge(symbol: chat.skipped ? "hand.raised.fill" : "bubble.left.fill",
                                  colors: chat.skipped ? Tone.muted : Tone.chats, size: 36)
                            Text(chat.title).font(.body.weight(.semibold)).lineLimit(1)
                            Spacer()
                            Toggle(chat.title, isOn: Binding(get: { chat.skipped }, set: { _ in model.toggleSkip(chat) }))
                                .toggleStyle(.switch)
                                .labelsHidden()
                        }
                    }
                }
            }
            if !approvals.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    SectionTitle(title: Pane.activity.title)
                    ApprovalList(approvals: Array(approvals.prefix(30)), showsDay: true)
                }
            }
        }
    }

    private func rows<Item: Identifiable, Row: View>(_ items: [Item], @ViewBuilder _ row: @escaping (Item) -> Row) -> some View {
        VStack(spacing: 0) {
            ForEach(items) { item in
                row(item).padding(.vertical, 10)
                if item.id != items.last?.id { Divider().padding(.leading, 50) }
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 6)
        .cardBackground()
    }
}
