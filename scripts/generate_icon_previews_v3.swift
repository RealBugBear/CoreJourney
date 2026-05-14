import AppKit
import Foundation

let outputDir = CommandLine.arguments.dropFirst().first
    ?? "design/icon_previews_v3"

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

func fillGradient(_ context: CGContext, colors: [NSColor], start: CGPoint, end: CGPoint) {
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

func roundedRectPath(_ rect: CGRect, radius: CGFloat) -> NSBezierPath {
    NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius)
}

func diamondPath(center: CGPoint, width: CGFloat, height: CGFloat) -> NSBezierPath {
    let path = NSBezierPath()
    path.move(to: CGPoint(x: center.x, y: center.y + height / 2))
    path.line(to: CGPoint(x: center.x + width / 2, y: center.y))
    path.line(to: CGPoint(x: center.x, y: center.y - height / 2))
    path.line(to: CGPoint(x: center.x - width / 2, y: center.y))
    path.close()
    return path
}

func savePathGem(_ url: URL) throws {
    let (bitmap, context) = makeContext()
    clipCanvas(context)
    fillGradient(
        context,
        colors: [color(0x0F1630), color(0x2B376E), color(0x7A67DA)],
        start: CGPoint(x: 120, y: 980),
        end: CGPoint(x: 920, y: 60)
    )
    glow(context, center: CGPoint(x: 230, y: 820), radius: 280, color: color(0x95F0E2, alpha: 0.12))
    glow(context, center: CGPoint(x: 770, y: 180), radius: 260, color: color(0xFFD496, alpha: 0.12))

    let frame = roundedRectPath(CGRect(x: 252, y: 188, width: 520, height: 648), radius: 176)
    frame.lineWidth = 14
    color(0xFFFFFF, alpha: 0.12).setStroke()
    frame.stroke()

    let road = NSBezierPath()
    road.move(to: CGPoint(x: 512, y: 250))
    road.curve(
        to: CGPoint(x: 612, y: 742),
        controlPoint1: CGPoint(x: 430, y: 378),
        controlPoint2: CGPoint(x: 460, y: 610)
    )
    road.curve(
        to: CGPoint(x: 512, y: 798),
        controlPoint1: CGPoint(x: 596, y: 770),
        controlPoint2: CGPoint(x: 558, y: 798)
    )

    let roadCopy = road.copy() as! NSBezierPath
    context.saveGState()
    roadCopy.lineWidth = 130
    roadCopy.lineCapStyle = .round
    roadCopy.addClip()
    let roadGradient = CGGradient(
        colorsSpace: CGColorSpaceCreateDeviceRGB(),
        colors: [color(0xFFFFFF, alpha: 0.98).cgColor, color(0xDDE5FF, alpha: 0.92).cgColor] as CFArray,
        locations: [0, 1]
    )!
    context.drawLinearGradient(
        roadGradient,
        start: CGPoint(x: 420, y: 220),
        end: CGPoint(x: 640, y: 820),
        options: []
    )
    context.restoreGState()

    stroke(road, width: 130, color: color(0xF7F8FF, alpha: 0.95), shadow: color(0x000000, alpha: 0.10).cgColor, blur: 24)

    let guide = NSBezierPath()
    guide.move(to: CGPoint(x: 512, y: 286))
    guide.curve(
        to: CGPoint(x: 554, y: 724),
        controlPoint1: CGPoint(x: 470, y: 408),
        controlPoint2: CGPoint(x: 486, y: 612)
    )
    stroke(guide, width: 18, color: color(0x84E9D9, alpha: 0.98), shadow: color(0x84E9D9, alpha: 0.18).cgColor, blur: 10)

    let waypoints = [
        CGPoint(x: 500, y: 348),
        CGPoint(x: 490, y: 474),
        CGPoint(x: 510, y: 612),
        CGPoint(x: 552, y: 724),
    ]
    for point in waypoints.dropLast() {
        fillDot(context, center: point, radius: 14, colors: [
            color(0xF2FCFA),
            color(0xBCEFE7),
            color(0x84E9D9),
        ])
    }

    let summit = diamondPath(center: CGPoint(x: 552, y: 724), width: 54, height: 54)
    color(0xFFD690, alpha: 0.98).setFill()
    context.saveGState()
    context.setShadow(offset: .zero, blur: 16, color: color(0xFFD690, alpha: 0.18).cgColor)
    summit.fill()
    context.restoreGState()

    context.restoreGState()
    try finish(bitmap, url)
}

func saveHorizonGate(_ url: URL) throws {
    let (bitmap, context) = makeContext()
    clipCanvas(context)
    fillGradient(
        context,
        colors: [color(0x111B2C), color(0x244663), color(0x6393B5)],
        start: CGPoint(x: 160, y: 980),
        end: CGPoint(x: 900, y: 70)
    )
    glow(context, center: CGPoint(x: 512, y: 230), radius: 220, color: color(0xFFFFFF, alpha: 0.06))
    glow(context, center: CGPoint(x: 760, y: 210), radius: 260, color: color(0xFFD59B, alpha: 0.10))

    let outer = roundedRectPath(CGRect(x: 236, y: 214, width: 552, height: 596), radius: 180)
    outer.lineWidth = 18
    color(0xF5F8FF, alpha: 0.92).setStroke()
    context.saveGState()
    context.setShadow(offset: .zero, blur: 20, color: color(0x000000, alpha: 0.12).cgColor)
    outer.stroke()
    context.restoreGState()

    let inner = roundedRectPath(CGRect(x: 344, y: 320, width: 336, height: 384), radius: 124)
    inner.lineWidth = 14
    color(0x95EFE0, alpha: 0.86).setStroke()
    inner.stroke()

    let line = NSBezierPath()
    line.move(to: CGPoint(x: 390, y: 382))
    line.curve(
        to: CGPoint(x: 612, y: 648),
        controlPoint1: CGPoint(x: 490, y: 440),
        controlPoint2: CGPoint(x: 522, y: 592)
    )
    stroke(line, width: 30, color: color(0xF6FBFF, alpha: 0.85))

    let horizon = NSBezierPath()
    horizon.move(to: CGPoint(x: 316, y: 520))
    horizon.line(to: CGPoint(x: 708, y: 520))
    stroke(horizon, width: 10, color: color(0xFFFFFF, alpha: 0.10))

    let destination = diamondPath(center: CGPoint(x: 612, y: 648), width: 60, height: 60)
    color(0xFFD68A, alpha: 0.98).setFill()
    context.saveGState()
    context.setShadow(offset: .zero, blur: 16, color: color(0xFFD68A, alpha: 0.20).cgColor)
    destination.fill()
    context.restoreGState()

    context.restoreGState()
    try finish(bitmap, url)
}

func saveMonolithJourney(_ url: URL) throws {
    let (bitmap, context) = makeContext()
    clipCanvas(context)
    fillGradient(
        context,
        colors: [color(0x151229), color(0x39295B), color(0x8B70D9)],
        start: CGPoint(x: 100, y: 1024),
        end: CGPoint(x: 920, y: 0)
    )
    glow(context, center: CGPoint(x: 512, y: 830), radius: 320, color: color(0xB99EFF, alpha: 0.10))

    let monolith = roundedRectPath(CGRect(x: 342, y: 176, width: 340, height: 672), radius: 142)
    color(0xF6F3FF, alpha: 0.95).setFill()
    context.saveGState()
    context.setShadow(offset: .zero, blur: 24, color: color(0x000000, alpha: 0.12).cgColor)
    monolith.fill()
    context.restoreGState()

    let cutout = roundedRectPath(CGRect(x: 420, y: 258, width: 184, height: 508), radius: 92)
    color(0x2B2050, alpha: 0.82).setFill()
    cutout.fill()

    let ascent = NSBezierPath()
    ascent.move(to: CGPoint(x: 468, y: 312))
    ascent.curve(
        to: CGPoint(x: 552, y: 704),
        controlPoint1: CGPoint(x: 442, y: 436),
        controlPoint2: CGPoint(x: 470, y: 608)
    )
    stroke(ascent, width: 22, color: color(0x92EEDF, alpha: 0.96), shadow: color(0x92EEDF, alpha: 0.18).cgColor, blur: 10)

    let waypoint1 = diamondPath(center: CGPoint(x: 464, y: 410), width: 28, height: 28)
    let waypoint2 = diamondPath(center: CGPoint(x: 486, y: 546), width: 28, height: 28)
    let summit = diamondPath(center: CGPoint(x: 552, y: 704), width: 44, height: 44)
    color(0xDDFBF6, alpha: 0.95).setFill()
    waypoint1.fill()
    waypoint2.fill()
    color(0xFFD68B, alpha: 0.98).setFill()
    summit.fill()

    let halo = roundedRectPath(CGRect(x: 286, y: 126, width: 452, height: 772), radius: 190)
    halo.lineWidth = 12
    color(0xFFFFFF, alpha: 0.07).setStroke()
    halo.stroke()

    context.restoreGState()
    try finish(bitmap, url)
}

let dirURL = URL(fileURLWithPath: outputDir, isDirectory: true)
try FileManager.default.createDirectory(at: dirURL, withIntermediateDirectories: true)

try savePathGem(dirURL.appendingPathComponent("preview_path_gem.png"))
try saveHorizonGate(dirURL.appendingPathComponent("preview_horizon_gate.png"))
try saveMonolithJourney(dirURL.appendingPathComponent("preview_monolith_journey.png"))
