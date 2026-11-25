import AppKit
import ImageIO
import SwiftUI

/// The hero's backdrop: soft morning light in a wood, and the leafy branch
/// the woodpecker works at, coming in from the card's right edge. `artwork` is the side of the
/// bird's frame at the card's right, so the branch passes under it; 0 hides the branch.
struct HeroScene: View {
    let artwork: CGFloat
    let inset: CGFloat

    private static let light = [Color(red: 0.97, green: 0.95, blue: 0.88), Color(red: 0.86, green: 0.90, blue: 0.78)]
    private static let green = Color(red: 0.62, green: 0.78, blue: 0.36)
    private static let branch = Bundle.main.url(forResource: "branch", withExtension: "png").flatMap(NSImage.init(contentsOf:))

    var body: some View {
        Canvas { context, size in
            context.fill(Path(CGRect(origin: .zero, size: size)),
                         with: .linearGradient(Gradient(colors: Self.light), startPoint: .zero,
                                               endPoint: CGPoint(x: size.width, y: size.height)))
            // Light through the canopy, and greenery far behind, out of focus.
            context.drawLayer { layer in
                layer.addFilter(.blur(radius: 50))
                layer.fill(Path(ellipseIn: CGRect(x: size.width * 0.1, y: -size.height * 0.3, width: size.width * 0.6, height: size.height * 0.8)),
                           with: .color(.white.opacity(0.7)))
                layer.fill(Path(ellipseIn: CGRect(x: -size.width * 0.1, y: size.height * 0.6, width: size.width * 0.5, height: size.height * 0.7)),
                           with: .color(Self.green.opacity(0.35)))
                layer.fill(Path(ellipseIn: CGRect(x: size.width * 0.6, y: -size.height * 0.2, width: size.width * 0.5, height: size.height * 0.6)),
                           with: .color(Self.green.opacity(0.3)))
            }
            guard artwork > 0, let image = Self.branch else { return }
            let frame = Self.birdFrame(in: size, artwork: artwork, inset: inset)
            // The branch's cut end leaves the card at its right edge; its upper side passes just
            // under the bird and takes the twig the bird pecks.
            let width = artwork * 2.0
            let height = width * Self.pixels(image).height / Self.pixels(image).width
            let rect = CGRect(x: size.width + 8 - width * 0.955, y: frame.minY + frame.height * 0.9 - height * 0.55,
                              width: width, height: height)
            context.drawLayer { layer in
                layer.addFilter(.shadow(color: .black.opacity(0.18), radius: 10, y: 8))
                layer.draw(Image(nsImage: image), in: rect)
            }
        }
        .accessibilityHidden(true)
    }

    /// The bird's frame, as the card lays it out: at the right, centred.
    static func birdFrame(in size: CGSize, artwork: CGFloat, inset: CGFloat) -> CGRect {
        CGRect(x: size.width - inset - artwork, y: (size.height - artwork * 0.745) / 2, width: artwork, height: artwork * 0.745)
    }

    /// In pixels: the pictures' declared resolution would size them in points.
    static func pixels(_ image: NSImage) -> CGSize {
        guard let bitmap = image.representations.first else { return image.size }
        return CGSize(width: bitmap.pixelsWide, height: bitmap.pixelsHigh)
    }
}

/// The moving part of the hero, on one clock: the woodpecker's frame from the GIF, and the twig
/// it pecks, shaken by the angle the GIF's leaf turns at that frame, about the same foot.
struct HeroMotion: View {
    let artwork: CGFloat
    let inset: CGFloat
    let animates: Bool

    private static let frames = PeckFrames()
    private static let twig = Bundle.main.url(forResource: "twig", withExtension: "png").flatMap(NSImage.init(contentsOf:))

    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / PeckFrames.rate, paused: !animates)) { timeline in
            let index = animates ? Int(timeline.date.timeIntervalSinceReferenceDate * PeckFrames.rate) : 0
            Canvas { context, size in
                guard artwork > 0 else { return }
                let frame = HeroScene.birdFrame(in: size, artwork: artwork, inset: inset)
                if let twig = Self.twig { Self.draw(twig, in: &context, frame: frame, shake: Self.frames.shake(index)) }
                if let bird = Self.frames.image(index) { context.draw(Image(decorative: bird, scale: 1), in: frame) }
            }
        }
        .accessibilityHidden(true)
    }

    /// The twig rises out of the bark at the foot of the bird's frame to where the GIF hangs the
    /// leaf, both ends as fractions of that frame; the picture's base fades into the bark.
    private static func draw(_ twig: NSImage, in context: inout GraphicsContext, frame: CGRect, shake: Double) {
        let base = CGPoint(x: frame.minX + frame.width * 0.6157, y: frame.maxY)
        let tip = CGPoint(x: frame.minX + frame.width * 0.6863, y: frame.minY + frame.height * 0.3316)
        let pictureBase = CGPoint(x: 15.1, y: 221.3), pictureTip = CGPoint(x: 417.4, y: 135.8)
        let angle = atan2(tip.y - base.y, tip.x - base.x) - atan2(pictureTip.y - pictureBase.y, pictureTip.x - pictureBase.x)
        let scale = hypot(tip.x - base.x, tip.y - base.y) / hypot(pictureTip.x - pictureBase.x, pictureTip.y - pictureBase.y)
        // The picture's base already fades out, so it is one transformed draw per frame.
        var placed = context
        placed.translateBy(x: base.x, y: base.y)
        placed.rotate(by: .degrees(shake))
        placed.rotate(by: .radians(angle))
        placed.scaleBy(x: scale, y: scale)
        placed.translateBy(x: -pictureBase.x, y: -pictureBase.y)
        placed.draw(Image(nsImage: twig), in: CGRect(origin: .zero, size: HeroScene.pixels(twig)))
    }
}

/// The woodpecker's GIF, one frame at a time, and the twig's shake at each frame, which the GIF's
/// generator writes beside it. A frame is decoded when shown, never all kept.
final class PeckFrames {
    static let rate = 25.0
    private let source = Bundle.main.url(forResource: "woodpecker", withExtension: "gif")
        .flatMap { CGImageSourceCreateWithURL($0 as CFURL, nil) }
    private let shakes = Bundle.main.url(forResource: "peck", withExtension: "json")
        .flatMap { try? Data(contentsOf: $0) }
        .flatMap { try? JSONDecoder().decode([Double].self, from: $0) } ?? []

    func image(_ index: Int) -> CGImage? {
        guard let source, CGImageSourceGetCount(source) > 0 else { return nil }
        return CGImageSourceCreateImageAtIndex(source, index % CGImageSourceGetCount(source),
                                               [kCGImageSourceShouldCache: false] as CFDictionary)
    }

    func shake(_ index: Int) -> Double { shakes.isEmpty ? 0 : shakes[index % shakes.count] }
}
