import AppKit

enum MenuBarIcon {
    /// A template image, so macOS tints it for a light or dark bar: a filled disc with the
    /// check cut out while active, a faint outline when paused or without permission.
    static func image(active: Bool) -> NSImage {
        let image = NSImage(size: NSSize(width: 18, height: 18), flipped: true) { _ in
            let check = NSBezierPath()
            check.move(to: NSPoint(x: 5.9, y: 9.2))
            check.line(to: NSPoint(x: 8.1, y: 11.4))
            check.line(to: NSPoint(x: 12.2, y: 6.9))
            check.lineCapStyle = .round
            check.lineJoinStyle = .round
            if active {
                NSColor.black.set()
                NSBezierPath(ovalIn: NSRect(x: 1.6, y: 1.6, width: 14.8, height: 14.8)).fill()
                check.lineWidth = 1.7
                NSGraphicsContext.current?.compositingOperation = .clear
                check.stroke()
            } else {
                NSColor(white: 0, alpha: 0.45).set()
                let ring = NSBezierPath(ovalIn: NSRect(x: 2.1, y: 2.1, width: 13.8, height: 13.8))
                ring.lineWidth = 1.4
                ring.stroke()
                check.lineWidth = 1.5
                check.stroke()
            }
            return true
        }
        image.isTemplate = true
        return image
    }
}
