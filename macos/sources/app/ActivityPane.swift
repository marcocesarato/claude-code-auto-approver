import AppKit
import AutoApproverCore
import SwiftUI

struct ApprovalList: View {
    let approvals: [Approval]
    var showsDay = false

    var body: some View {
        if approvals.isEmpty {
            EmptyState(symbol: "checkmark.seal", text: L10n.t(.noActivity))
        } else {
            VStack(spacing: 0) {
                ForEach(Array(approvals.enumerated()), id: \.offset) { index, approval in
                    HStack(alignment: .top, spacing: 14) {
                        Badge(symbol: approval.fromNotification ? "bell.badge.fill" : "macwindow",
                              colors: approval.fromNotification ? [.pink, .red] : [coral, .red], size: 44)
                            .accessibilityHidden(true)
                        VStack(alignment: .leading, spacing: 3) {
                            // The chat heads the row when known; the request says what was allowed.
                            Text(approval.chat ?? approval.label).font(.headline).lineLimit(1)
                            if let request = approval.request {
                                Text(request).font(.callout).foregroundStyle(.secondary).lineLimit(2)
                            }
                            Text([approval.chat == nil ? nil : approval.label,
                                  L10n.t(approval.fromNotification ? .notifications : .window)]
                                .compactMap { $0 }.joined(separator: " · "))
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                                .lineLimit(1)
                        }
                        Spacer(minLength: 8)
                        if approval.locked {
                            Image(systemName: "lock.fill").foregroundStyle(.secondary).accessibilityHidden(true)
                        }
                        Text(showsDay ? "\(L10n.day(approval.day)), \(approval.clock)" : approval.clock)
                            .font(.callout)
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 12)
                    .accessibilityElement(children: .combine)
                    if index < approvals.count - 1 { Divider().padding(.leading, 58) }
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 4)
            .cardBackground()
        }
    }
}


struct ActivityPane: View {
    enum Source: CaseIterable { case all, window, notifications }

    @ObservedObject var model: AppModel
    @State private var source = Source.all

    private var filter: some View {
        Picker(L10n.t(.paneActivity), selection: $source) {
            Text(L10n.t(.all)).tag(Source.all)
            Text(L10n.t(.window)).tag(Source.window)
            Text(L10n.t(.notifications)).tag(Source.notifications)
        }
        .pickerStyle(.segmented)
        .labelsHidden()
        .fixedSize()
        // On a light plate: the system control's dark text is unreadable on the gradient.
        .padding(4)
        .background(Color.white.opacity(0.92), in: Capsule())
        .environment(\.colorScheme, .light)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(L10n.t(.paneActivity).uppercased())
                .font(.caption.weight(.semibold))
                .tracking(1)
                .foregroundStyle(.white.opacity(0.8))
            Text("\(model.approvedToday)")
                .font(.system(size: 40, weight: .regular))
                .foregroundStyle(.white)
            Text(L10n.t(.approvedToday)).font(.title3).foregroundStyle(.white.opacity(0.85))
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 16) { filter; Spacer(); logButton }
                VStack(alignment: .leading, spacing: 12) { filter; logButton }
            }
            .controlSize(.large)
            .padding(.top, 10)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(LinearGradient(colors: hero, startPoint: .topLeading, endPoint: .bottomTrailing))
        )
        .accessibilityElement(children: .contain)
    }

    private var logButton: some View {
        Button(L10n.t(.openLog)) { NSWorkspace.shared.open(URL(fileURLWithPath: Settings.logPath)) }
            .buttonStyle(PillButtonStyle(filled: true))
    }

    var body: some View {
        let shown = model.approvals.filter { approval in
            (source == .all || (source == .notifications) == approval.fromNotification)
                && [approval.label, approval.chat ?? "", approval.request ?? "", L10n.day(approval.day)].contains(where: model.matches)
        }
        PaneScroll(title: Pane.activity.title) {
            header
            if shown.isEmpty {
                EmptyState(symbol: "clock.arrow.circlepath", text: L10n.t(.noActivity))
            }
            ForEach(Activity.byDay(shown), id: \.day) { day in
                VStack(alignment: .leading, spacing: 12) {
                    SectionTitle(title: L10n.day(day.day))
                    ApprovalList(approvals: day.approvals)
                }
            }
        }
    }
}
