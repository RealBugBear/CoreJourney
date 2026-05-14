import AppKit
import Foundation

let outputDir = CommandLine.arguments.dropFirst().first
    ?? "design/icon_previews_v4"

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

func finish(_ bitmap: NSBitmapImageRep, _ url: URL) throws {
    NSGraphicsContext.restoreGraphicsState()
    guard let data = bitmap.representation(using: .png, properties: [:]) else {
        fatalError("Unable to encode PNG")
    }
    try data.write(to: url)
}

func clipCanvas(_ context: CGContext) {
    let path = NSBezierPath(
        roundedRect: rect.insetBy(dx: 48, dy: 48),
        xRadius: 224,
        yRadius: 224
    )
    context.saveGState()
    path.addClip()
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

func fillDot(_ context: CGContext, center: CGPoint, radius: CGFloat, colors: [NSColor]) {
    let gradient = CGGradient(
        colorsSpace: CGColorSpaceCreateDeviceRGB(),
        colors: colors.map(\.cgColor) as CFArray,
        locations: [0.0, 0.65, 1.0]
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

func spiralPaths() -> (outer: NSBezierPath, inner: NSBezierPath) {
    let outer = NSBezierPath()
    outer.move(to: CGPoint(x: 734, y: 312))
    outer.curve(
        to: CGPoint(x: 336, y: 734),
        controlPoint1: CGPoint(x: 772, y: 474),
        controlPoint2: CGPoint(x: 608, y: 786)
    )
    outer.curve(
        to: CGPoint(x: 426, y: 324),
        controlPoint1: CGPoint(x: 170, y: 654),
        controlPoint2: CGPoint(x: 198, y: 372)
    )
    outer.curve(
        to: CGPoint(x: 630, y: 504),
        controlPoint1: CGPoint(x: 560, y: 286),
        controlPoint2: CGPoint(x: 668, y: 392)
    )
    outer.curve(
        to: CGPoint(x: 520, y: 620),
        controlPoint1: CGPoint(x: 626, y: 576),
        controlPoint2: CGPoint(x: 570, y: 640)
    )

    let inner = NSBezierPath()
    inner.move(to: CGPoint(x: 632, y: 396))
    inner.curve(
        to: CGPoint(x: 402, y: 590),
        controlPoint1: CGPoint(x: 646, y: 492),
        controlPoint2: CGPoint(x: 528, y: 614)
    )
    inner.curve(
        to: CGPoint(x: 472, y: 428),
        controlPoint1: CGPoint(x: 336, y: 544),
        controlPoint2: CGPoint(x: 346, y: 434)
    )
    inner.curve(
        to: CGPoint(x: 566, y: 500),
        controlPoint1: CGPoint(x: 526, y: 404),
        controlPoint2: CGPoint(x: 578, y: 450)
    )
    return (outer, inner)
}

func saveSpiralGlass(to url: URL) throws {
    let (bitmap, context) = makeContext()
    clipCanvas(context)
    drawGradient(
        context,
        colors: [color(0x0F1F30), color(0x214864), color(0x658EAF)],
        start: CGPoint(x: 140, y: 980),
        end: CGPoint(x: 900, y: 70)
    )
    glow(context, center: CGPoint(x: 760, y: 190), radius: 300, color: color(0xFFD8A1, alpha: 0.14))
    glow(context, center: CGPoint(x: 260, y: 800), radius: 340, color: color(0x91F0E3, alpha: 0.12))

    let ring = NSBezierPath(ovalIn: CGRect(x: 226, y: 226, width: 572, height: 572))
    ring.lineWidth = 14
    color(0xFFFFFF, alpha: 0.08).setStroke()
    ring.stroke()

    let centerDisk = NSBezierPath(ovalIn: CGRect(x: 306, y: 306, width: 412, height: 412))
    color(0xFFFFFF, alpha: 0.06).setFill()
    centerDisk.fill()

    let (outer, inner) = spiralPaths()
    stroke(
        outer,
        width: 66,
        color: color(0xF6F8FE, alpha: 0.96),
        shadow: color(0x05131D, alpha: 0.18).cgColor,
        blur: 22
    )

    let highlight = outer.copy() as! NSBezierPath
    stroke(
        highlight,
        width: 22,
        color: color(0xFFFFFF, alpha: 0.24)
    )

    stroke(
        inner,
        width: 24,
        color: color(0x94EFE2, alpha: 0.95),
        shadow: color(0x94EFE2, alpha: 0.16).cgColor,
        blur: 10
    )

    fillDot(context, center: CGPoint(x: 512, y: 510), radius: 46, colors: [
        color(0xFFF7E3),
        color(0xFFCD85),
        color(0xFFA160),
    ])

    context.restoreGState()
    try finish(bitmap, url)
}

func saveSpiralFrame(to url: URL) throws {
    let (bitmap, context) = makeContext()
    clipCanvas(context)
    drawGradient(
        context,
        colors: [color(0x121731), color(0x2C3A74), color(0x7E6ADD)],
        start: CGPoint(x: 120, y: 1000),
        end: CGPoint(x: 920, y: 30)
    )
    glow(context, center: CGPoint(x: 752, y: 188), radius: 280, color: color(0xFFD49B, alpha: 0.12))

    let outerFrame = NSBezierPath(
        roundedRect: CGRect(x: 246, y: 184, width: 532, height: 656),
        xRadius: 180,
        yRadius: 180
    )
    outerFrame.lineWidth = 16
    color(0xFFFFFF, alpha: 0.12).setStroke()
    outerFrame.stroke()

    let innerPanel = NSBezierPath(
        roundedRect: CGRect(x: 320, y: 258, width: 384, height: 508),
        xRadius: 136,
        yRadius: 136
    )
    color(0xFFFFFF, alpha: 0.05).setFill()
    innerPanel.fill()

    let (outer, inner) = spiralPaths()
    let scale = AffineTransform(scale: 0.88)
    let translate = AffineTransform(translationByX: 60, byY: 56)
    outer.transform(using: scale)
    inner.transform(using: scale)
    outer.transform(using: translate)
    inner.transform(using: translate)

    stroke(
        outer,
        width: 58,
        color: color(0xF7F7FE, alpha: 0.96),
        shadow: color(0x000000, alpha: 0.16).cgColor,
        blur: 20
    )
    stroke(
        inner,
        width: 20,
        color: color(0x8EECDE, alpha: 0.96),
        shadow: color(0x8EECDE, alpha: 0.14).cgColor,
        blur: 8
    )

    fillDot(context, center: CGPoint(x: 510, y: 508), radius: 40, colors: [
        color(0xFFF7E5),
        color(0xFFD188),
        color(0xFFA05E),
    ])

    context.restoreGState()
    try finish(bitmap, url)
}

let dirURL = URL(fileURLWithPath: outputDir, isDirectory: true)
try FileManager.default.createDirectory(at: dirURL, withIntermediateDirectories: true)

try saveSpiralGlass(to: dirURL.appendingPathComponent("preview_spiral_glass.png"))
try saveSpiralFrame(to: dirURL.appendingPathComponent("preview_spiral_frame.png"))
