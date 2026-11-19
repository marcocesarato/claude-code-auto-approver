import AppKit
import ApplicationServices

/// One accessibility element, read in a single round trip: the trees are walked every tick.
struct AXNode {
    private static let attributes = [kAXRoleAttribute, kAXTitleAttribute, kAXDescriptionAttribute,
                                     kAXValueAttribute, kAXChildrenAttribute] as CFArray

    let element: AXUIElement
    let role: String
    let title: String
    let detail: String
    let value: String
    let children: [AXUIElement]

    init?(_ element: AXUIElement) {
        var raw: CFArray?
        guard AXUIElementCopyMultipleAttributeValues(element, Self.attributes, AXCopyMultipleAttributeOptions(rawValue: 0), &raw) == .success,
              let v = raw as? [AnyObject], v.count == 5 else { return nil }
        self.element = element
        role = v[0] as? String ?? ""
        title = v[1] as? String ?? ""
        detail = v[2] as? String ?? ""
        value = v[3] as? String ?? ""
        children = v[4] as? [AXUIElement] ?? []
    }

    /// What a button shows: its title, else its description.
    var label: String { title.isEmpty ? detail : title }

    /// All of its text.
    var text: String { [title, detail, value].filter { !$0.isEmpty }.joined(separator: " ") }

    var isButton: Bool { role == kAXButtonRole }

    var actions: [String] {
        var names: CFArray?
        AXUIElementCopyActionNames(element, &names)
        return names as? [String] ?? []
    }

    func perform(_ action: String) -> AXError {
        AXUIElementPerformAction(element, action as CFString)
    }

    /// "Role(text)", for the log.
    var summary: String { "\(role.replacingOccurrences(of: "AX", with: ""))(\(text.prefix(60)))" }

    var parent: AXNode? {
        var p: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, kAXParentAttribute as CFString, &p) == .success,
              let p, CFGetTypeID(p) == AXUIElementGetTypeID() else { return nil }
        return AXNode(p as! AXUIElement)
    }

    /// The accessibility root of a running app, if it runs.
    static func application(_ bundleId: String) -> AXUIElement? {
        NSRunningApplication.runningApplications(withBundleIdentifier: bundleId).first
            .map { AXUIElementCreateApplication($0.processIdentifier) }
    }

    static func windows(of app: AXUIElement) -> [AXUIElement] {
        var windows: CFTypeRef?
        AXUIElementCopyAttributeValue(app, kAXWindowsAttribute as CFString, &windows)
        return windows as? [AXUIElement] ?? []
    }
}
