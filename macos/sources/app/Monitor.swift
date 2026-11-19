import ApplicationServices
import AutoApproverCore
import Foundation
import IOKit.pwr_mgt

/// Looks for a permission prompt every tick, in the window first, then on a notification.
final class Monitor {
    private(set) var active = true { didSet { onStateChange?() } }
    /// When a timed pause ends; nil while on, or paused until resumed by hand.
    private(set) var resumeAt: Date?
    /// The chats open in the Claude window, for the menu; written on the monitor queue.
    var openChats: [String] { chatsLock.lock(); defer { chatsLock.unlock() }; return chats }
    private var chats: [String] = []
    private let chatsLock = NSLock()
    var onStateChange: (() -> Void)?

    // One serial queue owns the walks and the counters.
    private let queue = DispatchQueue(label: "com.marcocesarato.ClaudeCodeAutoApprover.monitor", qos: .utility)
    private var timer: DispatchSourceTimer?
    private var tick = 0
    private var accepted = 0
    private var cooldown = 0
    private var warnedUntrusted = false
    private var sleepAssertion: IOPMAssertionID = 0

    func start() {
        let t = DispatchSource.makeTimerSource(queue: queue)
        t.schedule(deadline: .now(), repeating: Settings.pollInterval, leeway: .milliseconds(200))
        t.setEventHandler { [weak self] in self?.poll() }
        t.resume()
        timer = t
        keepAwake(true)
        let labels = Labels.wanted(fromFile: Settings.readLabels()).map { $0.joined(separator: " ") }.sorted()
        log("🔍 Monitoring — pressing: \(labels.joined(separator: ", "))")
    }

    /// Pauses for `duration` seconds, or until `resume()` when nil. Call on the main thread.
    func pause(for duration: TimeInterval?) {
        resumeAt = duration.map { Date().addingTimeInterval($0) }
        active = false
        keepAwake(false)
        log("⏹ Paused \(resumeAt.map { "until \($0)" } ?? "until resumed")")
    }

    /// Call on the main thread.
    func resume() {
        guard !active else { return }
        resumeAt = nil
        active = true
        keepAwake(true)
        log("▶️ Resumed")
    }

    private func poll() {
        tick += 1
        guard active else {
            if let at = resumeAt, Date() >= at { DispatchQueue.main.async { self.resume() } }
            return
        }
        if tick % 2400 == 0 { log("💓 Tick \(tick), \(accepted) accepted") }
        // A pressed dialog needs a moment to close: never press the same one twice.
        if cooldown > 0 { cooldown -= 1; return }
        guard AXIsProcessTrusted() else {
            if !warnedUntrusted { log("❌ No Accessibility permission — nothing pressed") }
            warnedUntrusted = true
            return
        }
        warnedUntrusted = false

        // Read every tick, so an edited labels file applies without a restart.
        let wanted = Labels.wanted(fromFile: Settings.readLabels())
        let skipped = Chats.skipped(fromFile: Settings.readSkippedChats())
        let label = ClaudeWindow.pressAllow(wanted, skipping: skipped)
            ?? NotificationBanners.pressAction(wanted, skipping: skipped)
        chatsLock.lock(); chats = ClaudeWindow.openChats; chatsLock.unlock()
        if let label {
            accepted += 1
            cooldown = 1
            log("🤖 Approved #\(accepted): pressed \"\(label)\"\(Screen.locked ? " 🔒" : "")")
        }
    }

    /// While auto-approve is on the Mac does not idle-sleep; the display still may, and
    /// the screen may lock. A closed lid on battery still sleeps.
    private func keepAwake(_ on: Bool) {
        if on, sleepAssertion == 0 {
            let r = IOPMAssertionCreateWithName(kIOPMAssertionTypePreventUserIdleSystemSleep as CFString,
                                                IOPMAssertionLevel(kIOPMAssertionLevelOn),
                                                "\(Product.name): auto-approve on" as CFString, &sleepAssertion)
            log(r == kIOReturnSuccess ? "☕️ Keeping the Mac awake" : "⚠️  Could not keep the Mac awake (\(r))")
        } else if !on, sleepAssertion != 0 {
            IOPMAssertionRelease(sleepAssertion)
            sleepAssertion = 0
            log("💤 The Mac may sleep again")
        }
    }
}
