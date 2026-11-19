import Foundation

/// Whether the screen is locked, from the distributed notifications loginwindow posts.
enum Screen {
    static private(set) var locked = false

    static func observe() {
        let center = DistributedNotificationCenter.default()
        center.addObserver(forName: .init("com.apple.screenIsLocked"), object: nil, queue: .main) { _ in
            locked = true
            log("🔒 Screen locked")
        }
        center.addObserver(forName: .init("com.apple.screenIsUnlocked"), object: nil, queue: .main) { _ in
            locked = false
            log("🔓 Screen unlocked")
        }
    }
}
