import AppKit
import ImageIO
import SwiftUI

/// The bird's frame, as the card lays it out: at the right, centred. `artwork` is its side; 0
/// leaves the hero without a picture, for a narrow pane.
private func birdFrame(in size: CGSize, artwork: CGFloat, inset: CGFloat) -> CGRect {
    CGRect(x: size.width - inset - artwork, y: (size.height - artwork * 0.745) / 2, width: artwork, height: artwork * 0.745)
}

/// In pixels: the pictures' declared resolution would size them in points.
private func pixels(_ image: NSImage) -> CGSize {
    guard let bitmap = image.representations.first else { return image.size }
    return CGSize(width: bitmap.pixelsWide, height: bitmap.pixelsHigh)
}

private func picture(_ name: String) -> NSImage? {
    Bundle.main.url(forResource: name, withExtension: "png").flatMap(NSImage.init(contentsOf:))
}

/// Light that falls through a canopy or a window, out of focus behind the scene.
private func backdrop(_ context: inout GraphicsContext, _ size: CGSize, light: [Color], glow: Color) {
    context.fill(Path(CGRect(origin: .zero, size: size)),
                 with: .linearGradient(Gradient(colors: light), startPoint: .zero, endPoint: CGPoint(x: size.width, y: size.height)))
    context.drawLayer { layer in
        layer.addFilter(.blur(radius: 50))
        layer.fill(Path(ellipseIn: CGRect(x: size.width * 0.1, y: -size.height * 0.3, width: size.width * 0.6, height: size.height * 0.8)),
                   with: .color(.white.opacity(0.7)))
        layer.fill(Path(ellipseIn: CGRect(x: -size.width * 0.1, y: size.height * 0.6, width: size.width * 0.5, height: size.height * 0.7)),
                   with: .color(glow.opacity(0.35)))
        layer.fill(Path(ellipseIn: CGRect(x: size.width * 0.6, y: -size.height * 0.2, width: size.width * 0.5, height: size.height * 0.6)),
                   with: .color(glow.opacity(0.3)))
    }
}

/// The sound of a strike, in a bubble: it pops in, holds and fades before the next strike,
/// which sets its bubble at `other` instead of `at`. `unit` sizes it, and its tail curls down
/// from `tail`, a fraction of its width from its middle, towards what was struck.
private func drawBubble(_ word: String, in context: inout GraphicsContext, at: CGPoint, other: CGPoint,
                        unit: CGFloat, tail: CGFloat, age: Int, odd: Bool) {
    let text = context.resolve(Text(word).font(.system(size: unit * 0.17, weight: .semibold, design: .rounded)).foregroundColor(coral))
    let measured = text.measure(in: CGSize(width: unit, height: unit))
    let width = measured.width + unit * 0.16, height = measured.height + unit * 0.07
    let place = odd ? other : at
    var bubble = context
    bubble.opacity = [1, 1, 1, 0.45][age]
    bubble.translateBy(x: place.x, y: place.y - CGFloat(age))
    bubble.rotate(by: .degrees(odd ? 5 : -5))
    let scale = [0.62, 1.08, 1, 0.98][age]
    bubble.scaleBy(x: scale, y: scale)
    var shape = Path(roundedRect: CGRect(x: -width / 2, y: -height / 2, width: width, height: height), cornerRadius: height / 2, style: .continuous)
    let foot = CGPoint(x: width * tail, y: height / 2 - 1), lean: CGFloat = tail < 0 ? -1 : 1
    shape.move(to: CGPoint(x: foot.x - lean * unit * 0.05, y: foot.y))
    shape.addQuadCurve(to: CGPoint(x: foot.x + lean * unit * 0.05, y: foot.y + unit * 0.07),
                       control: CGPoint(x: foot.x - lean * unit * 0.01, y: foot.y + unit * 0.05))
    shape.addQuadCurve(to: CGPoint(x: foot.x + lean * unit * 0.04, y: foot.y),
                       control: CGPoint(x: foot.x + lean * unit * 0.02, y: foot.y + unit * 0.03))
    shape.closeSubpath()
    bubble.drawLayer { layer in
        layer.addFilter(.shadow(color: .black.opacity(0.16), radius: 6, y: 2))
        layer.fill(shape, with: .color(.white))
    }
    bubble.draw(text, at: .zero)
}

/// The hero while auto-approve is paused: in a wood, the woodpecker pecks a twig that rises from
/// the leafy branch coming in from the card's right edge, and the **Allow once** leaf hanging
/// from the twig swings. The bird and the leaf are the GIF's frame; the twig is drawn here, on
/// the same clock, shaken by the angle the generator's shake file gives that frame.
struct WoodlandScene: View {
    let artwork: CGFloat
    let inset: CGFloat
    let animates: Bool

    private static let light = [Color(red: 0.97, green: 0.95, blue: 0.88), Color(red: 0.86, green: 0.90, blue: 0.78)]
    private static let green = Color(red: 0.62, green: 0.78, blue: 0.36)
    private static let branch = picture("branch"), twig = picture("twig")
    private static let frames = PeckFrames(gif: "woodland", values: "shake")

    var body: some View {
        ZStack {
            Canvas { context, size in
                backdrop(&context, size, light: Self.light, glow: Self.green)
                guard artwork > 0, let branch = Self.branch else { return }
                let frame = birdFrame(in: size, artwork: artwork, inset: inset)
                // The branch's cut end leaves the card at its right edge; its upper side passes just
                // under the bird and takes the twig.
                let width = artwork * 2.0
                let height = width * pixels(branch).height / pixels(branch).width
                let rect = CGRect(x: size.width + 8 - width * 0.955, y: frame.minY + frame.height * 0.9 - height * 0.55,
                                  width: width, height: height)
                context.drawLayer { layer in
                    layer.addFilter(.shadow(color: .black.opacity(0.18), radius: 10, y: 8))
                    layer.draw(Image(nsImage: branch), in: rect)
                }
            }
            TimelineView(.animation(minimumInterval: 1 / PeckFrames.rate, paused: !animates)) { timeline in
                let index = PeckFrames.index(at: timeline.date, animates: animates)
                Canvas { context, size in
                    guard artwork > 0 else { return }
                    let frame = birdFrame(in: size, artwork: artwork, inset: inset)
                    if let twig = Self.twig { Self.draw(twig, in: &context, frame: frame, shake: Self.frames.value(index)) }
                    if let bird = Self.frames.image(index) { context.draw(Image(decorative: bird, scale: 1), in: frame) }
                    // Above the bird's head, clear of the leaf.
                    if let struck = PeckFrames.strike(index) {
                        func point(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: frame.minX + frame.width * x, y: frame.minY + frame.height * y) }
                        drawBubble("tock", in: &context, at: point(0.86, 0.17), other: point(0.79, 0.08),
                                   unit: frame.width * 0.36, tail: -0.2, age: struck.age, odd: struck.odd)
                    }
                }
            }
        }
        .accessibilityHidden(true)
    }

    /// The twig rises out of the bark at the foot of the bird's frame to where the GIF hangs the
    /// leaf, both ends as fractions of that frame, and shakes about its foot; the picture's base
    /// fades into the bark.
    private static func draw(_ twig: NSImage, in context: inout GraphicsContext, frame: CGRect, shake: Double) {
        let base = CGPoint(x: frame.minX + frame.width * 0.6157, y: frame.maxY)
        let tip = CGPoint(x: frame.minX + frame.width * 0.6863, y: frame.minY + frame.height * 0.3316)
        let pictureBase = CGPoint(x: 15.1, y: 221.3), pictureTip = CGPoint(x: 417.4, y: 135.8)
        let angle = atan2(tip.y - base.y, tip.x - base.x) - atan2(pictureTip.y - pictureBase.y, pictureTip.x - pictureBase.x)
        let scale = hypot(tip.x - base.x, tip.y - base.y) / hypot(pictureTip.x - pictureBase.x, pictureTip.y - pictureBase.y)
        var placed = context
        placed.translateBy(x: base.x, y: base.y)
        placed.rotate(by: .degrees(shake))
        placed.rotate(by: .radians(angle))
        placed.scaleBy(x: scale, y: scale)
        placed.translateBy(x: -pictureBase.x, y: -pictureBase.y)
        placed.draw(Image(nsImage: twig), in: CGRect(origin: .zero, size: pixels(twig)))
    }
}

/// The hero while auto-approve runs: the woodpecker hovers over a big **Y** key and presses it,
/// as a person answers yes in a terminal. The bird is the GIF's frame; the key is drawn here, on
/// the same clock, pressed as deep as the generator's press file says at that frame.
struct KeyScene: View {
    let artwork: CGFloat
    let inset: CGFloat
    let animates: Bool

    private static let light = [Color(red: 0.99, green: 0.96, blue: 0.91), Color(red: 0.98, green: 0.86, blue: 0.77)]
    private static let frames = PeckFrames(gif: "woodpecker", values: "press")

    var body: some View {
        ZStack {
            Canvas { context, size in backdrop(&context, size, light: Self.light, glow: coral) }
            TimelineView(.animation(minimumInterval: 1 / PeckFrames.rate, paused: !animates)) { timeline in
                let index = PeckFrames.index(at: timeline.date, animates: animates)
                Canvas { context, size in
                    guard artwork > 0 else { return }
                    let frame = birdFrame(in: size, artwork: artwork, inset: inset)
                    // Where the beak strikes and how wide the key is, as fractions of the GIF's frame.
                    let strike = CGPoint(x: frame.minX + frame.width * 0.29, y: frame.minY + frame.height * 0.6493)
                    let side = frame.width * 0.396
                    Self.drawKey(in: &context, strike: strike, side: side, press: Self.frames.value(index))
                    if let bird = Self.frames.image(index) { context.draw(Image(decorative: bird, scale: 1), in: frame) }
                    if let struck = PeckFrames.strike(index) {
                        drawBubble("tick", in: &context, at: CGPoint(x: strike.x - side * 0.5, y: strike.y - side * 0.6),
                                   other: CGPoint(x: strike.x - side * 0.16, y: strike.y - side * 0.74),
                                   unit: side, tail: 0.18, age: struck.age, odd: struck.odd)
                    }
                }
            }
        }
        .accessibilityHidden(true)
    }

    /// A keycap seen from the front and above: a dished top in perspective, a front wall and two
    /// side walls tapering up to it, in a dark well. Pressed, the top sinks and the walls shorten;
    /// the beak's strike lands on the top's right half.
    private static func drawKey(in context: inout GraphicsContext, strike: CGPoint, side: CGFloat, press: Double) {
        let origin = CGPoint(x: strike.x - side * 0.62, y: strike.y - side * 0.3)
        func point(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: origin.x + x * side, y: origin.y + y * side) }
        func shape(_ corners: [(CGFloat, CGFloat, CGFloat)]) -> Path {
            let points = corners.map { point($0.0, $0.1) }
            return Path { path in
                path.move(to: CGPoint(x: (points[0].x + points[points.count - 1].x) / 2, y: (points[0].y + points[points.count - 1].y) / 2))
                for (index, corner) in points.enumerated() {
                    path.addArc(tangent1End: corner, tangent2End: points[(index + 1) % points.count], radius: corners[index].2 * side)
                }
                path.closeSubpath()
            }
        }
        func vertical(_ colors: [Color], _ path: Path) -> GraphicsContext.Shading {
            let box = path.boundingRect
            return .linearGradient(Gradient(colors: colors), startPoint: CGPoint(x: box.midX, y: box.minY), endPoint: CGPoint(x: box.midX, y: box.maxY))
        }
        func across(_ stops: [Gradient.Stop], _ path: Path) -> GraphicsContext.Shading {
            let box = path.boundingRect
            return .linearGradient(Gradient(stops: stops), startPoint: CGPoint(x: box.minX, y: 0), endPoint: CGPoint(x: box.maxX, y: 0))
        }
        let sink = 0.08 * press
        let ground = CGRect(origin: point(-0.08, 0.57), size: CGSize(width: side * 1.16, height: side * 0.2))
        context.drawLayer { layer in
            layer.addFilter(.blur(radius: side * 0.06))
            layer.fill(Path(ellipseIn: ground), with: .color(.black.opacity(0.22 + 0.06 * press)))
        }
        let well = shape([(-0.035, 0.55, 0.07), (1.035, 0.55, 0.07), (1.035, 0.71, 0.07), (-0.035, 0.71, 0.07)])
        context.fill(well, with: vertical([Color(red: 0.3, green: 0.22, blue: 0.2), Color(red: 0.13, green: 0.09, blue: 0.08)], well))
        context.stroke(well, with: .color(.white.opacity(0.12)), lineWidth: 0.8)

        let walls = shape([(0.1, 0.03 + sink, 0.05), (0.9, 0.03 + sink, 0.05), (1, 0.66, 0.07), (0, 0.66, 0.07)])
        context.fill(walls, with: vertical([Color(red: 0.88, green: 0.34, blue: 0.21), Color(red: 0.64, green: 0.17, blue: 0.13)], walls))
        // Light from the left: the left wall catches it, the right one turns from it.
        context.fill(walls, with: across([.init(color: .white.opacity(0.2), location: 0), .init(color: .clear, location: 0.16),
                                          .init(color: .clear, location: 0.84), .init(color: .black.opacity(0.22), location: 1)], walls))
        let front = shape([(0.12, 0.38 + sink, 0.02), (0.88, 0.38 + sink, 0.02), (0.985, 0.655, 0.06), (0.015, 0.655, 0.06)])
        context.fill(front, with: vertical([Color(red: 0.93, green: 0.4, blue: 0.24), Color(red: 0.76, green: 0.23, blue: 0.16)], front))
        context.fill(front, with: across([.init(color: .white.opacity(0.08), location: 0), .init(color: .clear, location: 0.3),
                                          .init(color: .black.opacity(0.1), location: 1)], front))
        context.stroke(walls, with: .color(.white.opacity(0.14)), lineWidth: 0.8)

        let top = shape([(0.15, sink, 0.07), (0.85, sink, 0.07), (0.88, 0.38 + sink, 0.06), (0.12, 0.38 + sink, 0.06)])
        context.drawLayer { layer in
            // The top's lip throws a thin shadow on the front wall.
            layer.addFilter(.shadow(color: .black.opacity(0.22), radius: 1.5, y: 1.2))
            layer.fill(top, with: vertical([Color(red: 1, green: 0.67, blue: 0.47), Color(red: 0.98, green: 0.5, blue: 0.31)], top))
        }
        // The top is dished: lit in its hollow, darker towards its rim.
        let box = top.boundingRect
        context.fill(top, with: .radialGradient(Gradient(colors: [.white.opacity(0.24), .clear, .black.opacity(0.07)]),
                                                center: CGPoint(x: box.midX - box.width * 0.1, y: box.midY - box.height * 0.12),
                                                startRadius: 0, endRadius: box.width * 0.6))
        context.stroke(top, with: .linearGradient(Gradient(colors: [.white.opacity(0.55), .white.opacity(0.12)]),
                                                  startPoint: CGPoint(x: box.midX, y: box.minY), endPoint: CGPoint(x: box.midX, y: box.maxY)),
                       lineWidth: 1)
        // The legend lies on the top, foreshortened with it, and is printed into it.
        var legend = context
        legend.translateBy(x: box.midX, y: box.midY)
        legend.scaleBy(x: 1, y: 0.8)
        let glyph = Text("Y").font(.system(size: side * 0.27, weight: .bold, design: .rounded))
        legend.draw(glyph.foregroundColor(Color(red: 0.55, green: 0.15, blue: 0.08).opacity(0.35)), at: CGPoint(x: 0, y: 1))
        legend.draw(glyph.foregroundColor(.white.opacity(0.96)), at: .zero)
    }
}

/// A woodpecker's GIF, one frame at a time, and the value its generator writes beside it for
/// each frame: how far the key is pressed, or the angle the twig is shaken by. A frame is
/// decoded when shown, never all kept.
final class PeckFrames {
    static let rate = 25.0
    private let source: CGImageSource?
    private let values: [Double]

    init(gif: String, values name: String) {
        source = Bundle.main.url(forResource: gif, withExtension: "gif").flatMap { CGImageSourceCreateWithURL($0 as CFURL, nil) }
        values = Self.read(name)
    }

    private static func read(_ name: String) -> [Double] {
        Bundle.main.url(forResource: name, withExtension: "json")
            .flatMap { try? Data(contentsOf: $0) }
            .flatMap { try? JSONDecoder().decode([Double].self, from: $0) } ?? []
    }

    /// The frame to show at `date`: the clock's while it animates, else a still one.
    static func index(at date: Date, animates: Bool) -> Int {
        animates ? Int(date.timeIntervalSinceReferenceDate * rate) : Demo.on ? Demo.frame : 0
    }

    func image(_ index: Int) -> CGImage? {
        guard let source, CGImageSourceGetCount(source) > 0 else { return nil }
        return CGImageSourceCreateImageAtIndex(source, index % CGImageSourceGetCount(source),
                                               [kCGImageSourceShouldCache: false] as CFDictionary)
    }

    func value(_ index: Int) -> Double { values.isEmpty ? 0 : values[index % values.count] }

    /// Both GIFs follow the generator's one timeline, so the key's press file, fully down at each
    /// strike, marks the strikes of both.
    private static let presses = read("press")
    private static let strikes = presses.indices.filter { presses[$0] == 1 }

    /// How many frames ago the last strike landed, while its bubble shows, and whether it was an odd one.
    static func strike(_ index: Int) -> (age: Int, odd: Bool)? {
        guard !presses.isEmpty else { return nil }
        let frame = index % presses.count
        guard let last = strikes.lastIndex(where: { $0 <= frame && frame - $0 < 4 }) else { return nil }
        return (frame - strikes[last], last % 2 == 1)
    }
}
