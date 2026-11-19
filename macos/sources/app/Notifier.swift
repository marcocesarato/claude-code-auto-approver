import Foundation
import UserNotifications

/// The app's own notifications; AppleScript banners when notifications are not allowed.
final class Notifier: NSObject, UNUserNotificationCenterDelegate {
    static let shared = Notifier()
    private var authorized = false

    func setup() {
        let center = UNUserNotificationCenter.current()
        center.delegate = self
        center.requestAuthorization(options: [.alert, .sound, .badge]) { ok, error in
            self.authorized = ok
            log(ok ? "✅ Notifications allowed"
                   : "⚠️  Notifications not allowed — using AppleScript banners (\(error?.localizedDescription ?? "no error"))")
        }
    }

    func send(title: String, body: String) {
        guard authorized else {
            let escape = { (s: String) in s.replacingOccurrences(of: "\\", with: "\\\\").replacingOccurrences(of: "\"", with: "\\\"") }
            DispatchQueue.global(qos: .utility).async {
                Self.runAppleScript("display notification \"\(escape(body))\" with title \"\(escape(title))\"")
            }
            return
        }
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        UNUserNotificationCenter.current().add(UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)) { error in
            if let error { log("⚠️  Notification failed: \(error.localizedDescription)") }
        }
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification,
                                withCompletionHandler handler: @escaping (UNNotificationPresentationOptions) -> Void) {
        handler([.banner, .sound])
    }

    /// Runs an AppleScript, killed after `timeout` so a hung script never stalls its caller.
    private static func runAppleScript(_ source: String, timeout: TimeInterval = 5) {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        task.arguments = ["-e", source]
        task.standardOutput = FileHandle.nullDevice
        task.standardError = FileHandle.nullDevice
        do { try task.run() } catch {
            log("❌ osascript: \(error.localizedDescription)")
            return
        }
        let deadline = Date().addingTimeInterval(timeout)
        while task.isRunning, Date() < deadline { Thread.sleep(forTimeInterval: 0.05) }
        if task.isRunning {
            task.terminate()
            log("❌ osascript timed out after \(Int(timeout)) s")
        }
    }
}
