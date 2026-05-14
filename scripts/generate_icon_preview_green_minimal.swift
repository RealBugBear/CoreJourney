import AppKit
import Foundation

let outputPath = CommandLine.arguments.dropFirst().first
    ?? "design/icon_previews_green/preview_green_minimal.png"

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
        locations: [0, 0.62, 1]
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

func stripePath(offset: CGFloat) -> NSBezierPath {
    let path = NSBezierPath()
    path.move(to: CGPoint(x: 512 + offset * 0.3, y: 770))
    path.curve(
        to: CGPoint(x: 630 + offset, y: 426),
        controlPoint1: CGPoint(x: 586 + offset * 0.3, y: 700),
        controlPoint2: CGPoint(x: 668 + offset * 0.85, y: 560)
    )
    path.curve(
        to: CGPoint(x: 516 + offset * 0.18, y: 254),
        controlPoint1: CGPoint(x: 602 + offset * 0.5, y: 330),
        controlPoint2: CGPoint(x: 556 + offset * 0.16, y: 270)
    )
    return path
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
        color(0x0C3124),
        color(0x0C6A49),
        color(0x009E6B),
        color(0x79DDB4),
    ],
    start: CGPoint(x: 120, y: 980),
    end: CGPoint(x: 910, y: 70)
)

glow(context, center: CGPoint(x: 806, y: 198), radius: 260, color: color(0xE5FFF2, alpha: 0.10))
glow(context, center: CGPoint(x: 226, y: 838), radius: 240, color: color(0xA9ECCC, alpha: 0.08))

let frame = NSBezierPath(
    roundedRect: CGRect(x: 192, y: 146, width: 640, height: 732),
    xRadius: 208,
    yRadius: 208
)
frame.lineWidth = 8
color(0xFFFFFF, alpha: 0.10).setStroke()
frame.stroke()

let plate = NSBezierPath(
    roundedRect: CGRect(x: 268, y: 220, width: 488, height: 584),
    xRadius: 170,
    yRadius: 170
)
color(0xFFFFFF, alpha: 0.04).setFill()
plate.fill()

let outerLeft = NSBezierPath()
outerLeft.move(to: CGPoint(x: 430, y: 758))
outerLeft.curve(
    to: CGPoint(x: 380, y: 498),
    controlPoint1: CGPoint(x: 394, y: 690),
    controlPoint2: CGPoint(x: 360, y: 590)
)
outerLeft.curve(
    to: CGPoint(x: 470, y: 258),
    controlPoint1: CGPoint(x: 402, y: 392),
    controlPoint2: CGPoint(x: 432, y: 300)
)

let outerRight = NSBezierPath()
outerRight.move(to: CGPoint(x: 594, y: 758))
outerRight.curve(
    to: CGPoint(x: 660, y: 500),
    controlPoint1: CGPoint(x: 632, y: 690),
    controlPoint2: CGPoint(x: 678, y: 590)
)
outerRight.curve(
    to: CGPoint(x: 552, y: 258),
    controlPoint1: CGPoint(x: 638, y: 392),
    controlPoint2: CGPoint(x: 598, y: 300)
)

stroke(outerLeft, width: 28, color: color(0xB7F0D7, alpha: 0.82))
stroke(outerRight, width: 28, color: color(0xB7F0D7, alpha: 0.82))

let offsets: [CGFloat] = [-34, 0, 34]
let widths: [CGFloat] = [42, 42, 38]
for (index, offset) in offsets.enumerated() {
    let path = stripePath(offset: offset)
    stroke(
        path,
        width: widths[index],
        color: color(0xFFFFFF, alpha: 0.97),
        shadow: color(0x083927, alpha: 0.12).cgColor,
        blur: 10
    )
}

fillDot(context, center: CGPoint(x: 512, y: 162), radius: 18, colors: [
    color(0xF7FFF9),
    color(0xBFEFDC),
    color(0x6FD4A8),
])

fillDot(context, center: CGPoint(x: 512, y: 860), radius: 24, colors: [
    color(0xF7FFF9),
    color(0xC9F5E2),
    color(0x7BE0B7),
])

context.restoreGState()
try finish(bitmap, to: outputURL)
