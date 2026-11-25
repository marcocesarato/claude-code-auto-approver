import AppKit
import AutoApproverCore
import SwiftUI

struct ChatsPane: View {
    @ObservedObject var model: AppModel

    var body: some View {
        let chats = model.chats.filter { model.matches($0.title) }
        GeometryReader { geo in
            // Pane padding is 28 per side; two columns once each card can have ~250 pt.
            let columns = geo.size.width - 56 >= 540 ? 2 : 1
            PaneScroll(title: Pane.chats.title) {
                if model.trusted {
                    banner(count: chats.filter(\.isOpen).count)
                    section(L10n.t(.openNow), chats.filter(\.isOpen), columns)
                } else {
                    // The chats are read from the Claude window, which needs Accessibility.
                    EmptyState(symbol: "lock.shield", text: L10n.t(.needsAccessBody))
                }
                let closed = chats.filter { !$0.isOpen }
                if !closed.isEmpty { section(L10n.t(.skippedClosed), closed, columns) }
            }
        }
    }

    private func banner(count: Int) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(L10n.t(.openNow).uppercased())
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white.opacity(0.8))
            Text("\(count) \(L10n.t(.openNow).lowercased())")
                .font(.system(size: 34, weight: .regular))
                .foregroundStyle(.white)
                .lineLimit(2)
            Text(L10n.t(.skipHint))
                .font(.title3)
                .foregroundStyle(.white.opacity(0.85))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(26)
        .background(RoundedRectangle(cornerRadius: 22, style: .continuous)
            .fill(LinearGradient(colors: hero, startPoint: .topLeading, endPoint: .bottomTrailing)))
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder private func section(_ title: String, _ chats: [AppModel.Chat], _ columns: Int) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle(title: title)
            if chats.isEmpty {
                EmptyState(symbol: "bubble.left.and.bubble.right", text: L10n.t(.noChats))
            } else {
                let rows = stride(from: 0, to: chats.count, by: columns).map { Array(chats[$0..<min($0 + columns, chats.count)]) }
                VStack(spacing: 16) {
                    ForEach(rows, id: \.first?.id) { row in
                        HStack(alignment: .top, spacing: 16) {
                            ForEach(row, id: \.id) { card($0) }
                            if row.count < columns { Color.clear.frame(maxWidth: .infinity, maxHeight: 0) }
                        }
                    }
                }
            }
        }
    }

    private func card(_ chat: AppModel.Chat) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text((chat.skipped ? L10n.t(.skippedChats) : L10n.t(.openNow)).uppercased())
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(chat.title)
                .font(.system(size: 22, weight: .regular))
                .lineLimit(2)
                .frame(maxWidth: .infinity, minHeight: 56, alignment: .topLeading)
            HStack {
                Badge(symbol: chat.skipped ? "hand.raised.fill" : "bubble.left.fill",
                      colors: chat.skipped ? Tone.muted : Tone.chats, size: 36)
                Spacer()
                Toggle(L10n.t(.skipChats), isOn: Binding(get: { chat.skipped }, set: { _ in model.toggleSkip(chat) }))
                    .toggleStyle(.switch)
                    .labelsHidden()
                    .accessibilityLabel("\(L10n.t(.skipChats)): \(chat.title)")
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardBackground()
    }
}
