// Renders the app icon as an .iconset: swiftc scripts/make-icon.swift -o make-icon && ./make-icon <dir>.iconset
import Cocoa

// Glass disc and check on coral, drawn on Apple's icon grid: an 824-point body
// centred on a 1024 canvas. Design units are 0–100 across the body, y down.
let sizes: [(Int, String)] = [
    (16, "icon_16x16.png"), (32, "icon_16x16@2x.png"),
    (32, "icon_32x32.png"), (64, "icon_32x32@2x.png"),
    (128, "icon_128x128.png"), (256, "icon_128x128@2x.png"),
    (256, "icon_256x256.png"), (512, "icon_256x256@2x.png"),
    (512, "icon_512x512.png"), (1024, "icon_512x512@2x.png"),
]

func rgb(_ hex: UInt32, _ a: CGFloat = 1) -> NSColor {
    NSColor(srgbRed: CGFloat(hex >> 16 & 0xFF) / 255, green: CGFloat(hex >> 8 & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255, alpha: a)
}
func white(_ a: CGFloat) -> NSColor { NSColor(white: 1, alpha: a) }

func draw(size px: Int) -> NSImage {
    let s = CGFloat(px)
    return NSImage(size: NSSize(width: s, height: s), flipped: true) { _ in
        let u = s * 824 / 1024 / 100           // one design unit
        let o = s * 100 / 1024                 // body offset
        func p(_ x: CGFloat, _ y: CGFloat) -> NSPoint { NSPoint(x: o + x * u, y: o + y * u) }
        func r(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat) -> NSRect { NSRect(x: o + x * u, y: o + y * u, width: w * u, height: h * u) }
        // NSShadow offsets ignore the flip: a negative height casts downward here.
        func shadow(_ dy: CGFloat, _ blur: CGFloat, _ a: CGFloat) {
            let sh = NSShadow()
            sh.shadowColor = NSColor(white: 0, alpha: a)
            sh.shadowOffset = NSSize(width: 0, height: -dy * u)
            sh.shadowBlurRadius = blur * u
            sh.set()
        }

        let body = NSBezierPath(roundedRect: r(0, 0, 100, 100), xRadius: 22.5 * u, yRadius: 22.5 * u)

        // Body with its own soft drop shadow, as macOS icons carry.
        NSGraphicsContext.saveGraphicsState()
        shadow(1.2, 2.4, 0.28)
        rgb(0xE0482F).setFill()
        body.fill()
        NSGraphicsContext.restoreGraphicsState()

        NSGraphicsContext.saveGraphicsState()
        body.addClip()
        NSGradient(starting: rgb(0xFF9A6B), ending: rgb(0xE0482F))!.draw(in: r(0, 0, 100, 100), angle: 90)
        NSGradient(starting: white(0.38), ending: white(0))!
            .draw(fromCenter: p(25, 10), radius: 0, toCenter: p(25, 10), radius: 80 * u, options: [])

        // Glass disc: translucent fill, specular rim, gloss.
        let disc = NSBezierPath(ovalIn: r(21, 22, 58, 58))
        NSGraphicsContext.saveGraphicsState()
        shadow(2.4, 2.6, 0.32)
        white(0.16).setFill()
        disc.fill()
        NSGraphicsContext.restoreGraphicsState()
        NSGraphicsContext.saveGraphicsState()
        disc.addClip()
        NSGradient(starting: white(0.42), ending: white(0.10))!.draw(in: r(21, 22, 58, 58), angle: 90)
        white(0.18).setFill()
        NSBezierPath(ovalIn: r(30, 25, 40, 16)).fill()
        NSGraphicsContext.restoreGraphicsState()

        let ring = NSBezierPath(ovalIn: r(20.45, 21.45, 59.1, 59.1))
        ring.append(NSBezierPath(ovalIn: r(21.55, 22.55, 56.9, 56.9)))
        ring.windingRule = .evenOdd
        NSGraphicsContext.saveGraphicsState()
        ring.addClip()
        NSGradient(colors: [white(0.95), white(0.12), white(0.55)], atLocations: [0, 0.45, 1],
                   colorSpace: .sRGB)!.draw(in: r(20, 21, 60, 60), angle: 45)
        NSGraphicsContext.restoreGraphicsState()

        // Check.
        let check = NSBezierPath()
        check.move(to: p(37, 52)); check.line(to: p(46.5, 61.5)); check.line(to: p(64.5, 41.5))
        check.lineWidth = 7.2 * u
        check.lineCapStyle = .round; check.lineJoinStyle = .round
        NSGraphicsContext.saveGraphicsState()
        shadow(1.6, 2.2, 0.30)
        NSColor.white.setStroke()
        check.stroke()
        NSGraphicsContext.restoreGraphicsState()
        NSGraphicsContext.restoreGraphicsState()

        // Hairline edge light around the body.
        white(0.22).setStroke()
        let edge = NSBezierPath(roundedRect: r(0.25, 0.25, 99.5, 99.5), xRadius: 22.3 * u, yRadius: 22.3 * u)
        edge.lineWidth = max(1, 0.5 * u)
        edge.stroke()
        return true
    }
}

let outDir = CommandLine.arguments[1]
for (sz, name) in sizes {
    let img = draw(size: sz)
    guard let tiff = img.tiffRepresentation,
          let bmp = NSBitmapImageRep(data: tiff),
          let png = bmp.representation(using: .png, properties: [:]) else { continue }
    try! png.write(to: URL(fileURLWithPath: outDir).appendingPathComponent(name))
    print("  ✓ \(name)")
}
