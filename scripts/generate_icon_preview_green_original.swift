import AppKit
import Foundation

let outputPath = CommandLine.arguments.dropFirst().first
    ?? "design/icon_previews_green/preview_green_original.png"

let canvas = CGSize(width: 1024, height: 1024)
let rect = CGRect(origin: .zero, size: canvas)

func color(_ hex: Int, alpha: CGFloat = 1.0) -> NSColor {
    NSColor(
        calibratedRed: CGFloat((hex >> 16) & 0xff) / 255.0,
        green: CGFloat((hex >> 8) & 0xff) / 255.0,
        blue: CGFloat(hex & 0xff) / 255.0,
        alpha: alpha
    )
}

func makeContext() -> (NSBitmapImageRep, CGContext) {
    let bitmap = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: Int(canvas.width),
        pixelsHigh: Int(canvas.height),
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    )!
    let graphicsContext = NSGraphicsContext(bitmapImageRep: bitmap)!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = graphicsContext
    let context = graphicsContext.cgContext
    context.setAllowsAntialiasing(true)
    context.setShouldAntialias(true)
    return (bitmap, context)
}

func finish(_ bitmap: NSBitmapImageRep, to url: URL) throws {
    NSGraphicsContext.restoreGraphicsState()
    guard let data = bitmap.representation(using: .png, properties: [:]) else {
        fatalError("Unable to encode PNG")
    }
    try data.write(to: url)
}

func stroke(_ path: NSBezierPath, width: CGFloat, color: NSColor, shadow: CGColor? = nil, blur: CGFloat = 0) {
    let context = NSGraphicsContext.current!.cgContext
    path.lineWidth = width
    path.lineCapStyle = .round
    path.lineJoinStyle = .round
    if let shadow {
        context.saveGState()
        context.setShadow(offset: .zero, blur: blur, color: shadow)
        color.setStroke()
        path.stroke()
        context.restoreGState()
    } else {
        color.setStroke()
        path.stroke()
    }
}

func drawGradient(_ context: CGContext, colors: [NSColor], start: CGPoint, end: CGPoint) {
    let gradient = CGGradient(
        colorsSpace: CGColorSpaceCreateDeviceRGB(),
        colors: colors.map(\.cgColor) as CFArray,
        locations: nil
    )!
    context.drawLinearGradient(gradient, start: start, end: end, options: [])
}

func glow(_ context: CGContext, center: CGPoint, radius: CGFloat, color: NSColor) {
    let gradient = CGGradient(
        colorsSpace: CGColorSpaceCreateDeviceRGB(),
        colors: [color.cgColor, color.withAlphaComponent(0).cgColor] as CFArray,
        locations: [0, 1]
    )!
    context.drawRadialGradient(
        gradient,
        startCenter: center,
        startRadius: 0,
        endCenter: center,
        endRadius: radius,
        options: []
    )
}

func fillDot(_ context: CGContext, center: CGPoint, radius: CGFloat, colors: [NSColor]) {
    let gradient = CGGradient(
        colorsSpace: CGColorSpaceCreateDeviceRGB(),
        colors: colors.map(\.cgColor) as CFArray,
        locations: [0, 0.6, 1]
    )!
    context.drawRadialGradient(
        gradient,
        startCenter: center,
        startRadius: 0,
        endCenter: center,
        endRadius: radius,
        options: []
    )
}

func makeLeafStripe(index: Int) -> NSBezierPath {
    let xOffset = CGFloat(index - 3) * 38.0
    let lowerInset = CGFloat(index) * 12.0
    let path = NSBezierPath()
    path.move(to: CGPoint(x: 512 + xOffset * 0.55, y: 796 - lowerInset))
    path.curve(
        to: CGPoint(x: 512 + xOffset + 118, y: 388 + lowerInset * 0.45),
        controlPoint1: CGPoint(x: 560 + xOffset * 0.3, y: 730 - lowerInset * 0.35),
        controlPoint2: CGPoint(x: 658 + xOffset * 0.8, y: 566 + lowerInset * 0.25)
    )
    path.curve(
        to: CGPoint(x: 512 + xOffset * 0.35, y: 190 + lowerInset * 0.18),
        controlPoint1: CGPoint(x: 548 + xOffset * 0.5, y: 306 + lowerInset * 0.2),
        controlPoint2: CGPoint(x: 522 + xOffset * 0.18, y: 238 + lowerInset * 0.1)
    )
    return path
}

func drawSeedMark(_ context: CGContext) {
    let outer = NSBezierPath()
    outer.move(to: CGPoint(x: 512, y: 144))
    outer.curve(
        to: CGPoint(x: 560, y: 96),
        controlPoint1: CGPoint(x: 530, y: 124),
        controlPoint2: CGPoint(x: 546, y: 108)
    )
    outer.curve(
        to: CGPoint(x: 596, y: 144),
        controlPoint1: CGPoint(x: 578, y: 108),
        controlPoint2: CGPoint(x: 592, y: 124)
    )
    outer.curve(
        to: CGPoint(x: 560, y: 196),
        controlPoint1: CGPoint(x: 598, y: 168),
        controlPoint2: CGPoint(x: 582, y: 192)
    )
    outer.curve(
        to: CGPoint(x: 512, y: 144),
        controlPoint1: CGPoint(x: 534, y: 192),
        controlPoint2: CGPoint(x: 514, y: 168)
    )
    color(0xFFFFFF, alpha: 0.98).setFill()
    context.saveGState()
    context.setShadow(offset: .zero, blur: 12, color: color(0x0A4D35, alpha: 0.16).cgColor)
    outer.fill()
    context.restoreGState()

    fillDot(context, center: CGPoint(x: 556, y: 144), radius: 16, colors: [
        color(0xF4FFF9),
        color(0xBAF0D8),
        color(0x5DC79D),
    ])
}

let outputURL = URL(fileURLWithPath: outputPath)
try FileManager.default.createDirectory(
    at: outputURL.deletingLastPathComponent(),
    withIntermediateDirectories: true
)

let (bitmap, context) = makeContext()

let clipPath = NSBezierPath(
    roundedRect: rect.insetBy(dx: 58, dy: 58),
    xRadius: 222,
    yRadius: 222
)
context.saveGState()
clipPath.addClip()

drawGradient(
    context,
    colors: [
        color(0x0B2D22),
        color(0x0F5B42),
        color(0x009E6B),
        color(0x6FD4A8),
    ],
    start: CGPoint(x: 120, y: 980),
    end: CGPoint(x: 910, y: 70)
)

glow(context, center: CGPoint(x: 214, y: 850), radius: 280, color: color(0xB3F0D8, alpha: 0.14))
glow(context, center: CGPoint(x: 790, y: 180), radius: 260, color: color(0xD9FFF0, alpha: 0.12))

let frame = NSBezierPath(
    roundedRect: CGRect(x: 178, y: 142, width: 668, height: 740),
    xRadius: 210,
    yRadius: 210
)
frame.lineWidth = 8
color(0xFFFFFF, alpha: 0.12).setStroke()
frame.stroke()

let softPlate = NSBezierPath(
    roundedRect: CGRect(x: 232, y: 194, width: 560, height: 636),
    xRadius: 186,
    yRadius: 186
)
color(0xFFFFFF, alpha: 0.05).setFill()
softPlate.fill()

for index in 0..<7 {
    let stripe = makeLeafStripe(index: index)
    let width = CGFloat(max(26, 44 - index * 3))
    stroke(
        stripe,
        width: width,
        color: color(0xFFFFFF, alpha: 0.97),
        shadow: color(0x063223, alpha: 0.15).cgColor,
        blur: 12
    )

    if index < 5 {
        let highlight = stripe.copy() as! NSBezierPath
        stroke(highlight, width: max(8, width * 0.26), color: color(0xF1FFF8, alpha: 0.18))
    }
}

let baseLeaf = NSBezierPath()
baseLeaf.move(to: CGPoint(x: 420, y: 810))
baseLeaf.curve(
    to: CGPoint(x: 360, y: 620),
    controlPoint1: CGPoint(x: 376, y: 760),
    controlPoint2: CGPoint(x: 334, y: 692)
)
baseLeaf.curve(
    to: CGPoint(x: 448, y: 520),
    controlPoint1: CGPoint(x: 378, y: 566),
    controlPoint2: CGPoint(x: 420, y: 540)
)
stroke(baseLeaf, width: 22, color: color(0xA7EBD0, alpha: 0.85))

let baseLeafRight = NSBezierPath()
baseLeafRight.move(to: CGPoint(x: 698, y: 808))
baseLeafRight.curve(
    to: CGPoint(x: 758, y: 622),
    controlPoint1: CGPoint(x: 742, y: 760),
    controlPoint2: CGPoint(x: 784, y: 692)
)
baseLeafRight.curve(
    to: CGPoint(x: 670, y: 522),
    controlPoint1: CGPoint(x: 740, y: 568),
    controlPoint2: CGPoint(x: 698, y: 540)
)
stroke(baseLeafRight, width: 22, color: color(0xA7EBD0, alpha: 0.85))

drawSeedMark(context)

context.restoreGState()
try finish(bitmap, to: outputURL)
