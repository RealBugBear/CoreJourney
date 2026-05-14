import AppKit
import Foundation

let outputDir = CommandLine.arguments.dropFirst().first
    ?? "design/icon_previews_v2"

let size = CGSize(width: 1024, height: 1024)
let rect = CGRect(origin: .zero, size: size)

func color(_ hex: Int, alpha: CGFloat = 1.0) -> NSColor {
    NSColor(
        calibratedRed: CGFloat((hex >> 16) & 0xff) / 255.0,
        green: CGFloat((hex >> 8) & 0xff) / 255.0,
        blue: CGFloat(hex & 0xff) / 255.0,
        alpha: alpha
    )
}

func makeBitmapContext() -> (NSBitmapImageRep, CGContext) {
    let bitmap = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: Int(size.width),
        pixelsHigh: Int(size.height),
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

func finishBitmap(_ bitmap: NSBitmapImageRep, to url: URL) throws {
    NSGraphicsContext.restoreGraphicsState()
    guard let png = bitmap.representation(using: .png, properties: [:]) else {
        fatalError("Unable to encode PNG")
    }
    try png.write(to: url)
}

func clipRoundedRect(_ context: CGContext, inset: CGFloat = 48, radius: CGFloat = 220) {
    let path = NSBezierPath(
        roundedRect: rect.insetBy(dx: inset, dy: inset),
        xRadius: radius,
        yRadius: radius
    )
    context.saveGState()
    path.addClip()
}

func backgroundGradient(_ context: CGContext, colors: [NSColor], start: CGPoint, end: CGPoint) {
    let gradient = CGGradient(
        colorsSpace: CGColorSpaceCreateDeviceRGB(),
        colors: colors.map(\.cgColor) as CFArray,
        locations: nil
    )!
    context.drawLinearGradient(gradient, start: start, end: end, options: [])
}

func radialGlow(_ context: CGContext, center: CGPoint, radius: CGFloat, glow: NSColor) {
    let gradient = CGGradient(
        colorsSpace: CGColorSpaceCreateDeviceRGB(),
        colors: [glow.cgColor, glow.withAlphaComponent(0).cgColor] as CFArray,
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

func strokePath(
    _ path: NSBezierPath,
    color stroke: NSColor,
    width: CGFloat,
    shadow: CGColor? = nil,
    blur: CGFloat = 0
) {
    let context = NSGraphicsContext.current!.cgContext
    path.lineWidth = width
    path.lineCapStyle = .round
    path.lineJoinStyle = .round
    if let shadow {
        context.saveGState()
        context.setShadow(offset: .zero, blur: blur, color: shadow)
        stroke.setStroke()
        path.stroke()
        context.restoreGState()
    } else {
        stroke.setStroke()
        path.stroke()
    }
}

func drawDot(_ context: CGContext, center: CGPoint, radius: CGFloat, colors: [NSColor]) {
    let gradient = CGGradient(
        colorsSpace: CGColorSpaceCreateDeviceRGB(),
        colors: colors.map(\.cgColor) as CFArray,
        locations: [0.0, 0.6, 1.0]
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

func drawSoftRing(center: CGPoint, radius: CGFloat, lineWidth: CGFloat, stroke: NSColor) {
    let ring = NSBezierPath()
    ring.appendArc(withCenter: center, radius: radius, startAngle: 0, endAngle: 360)
    ring.lineWidth = lineWidth
    stroke.setStroke()
    ring.stroke()
}

func saveSpiralBreath(to url: URL) throws {
    let (bitmap, context) = makeBitmapContext()
    clipRoundedRect(context)
    backgroundGradient(
        context,
        colors: [color(0x0C2030), color(0x1E4962), color(0x5C87A4)],
        start: CGPoint(x: 150, y: 980),
        end: CGPoint(x: 900, y: 70)
    )
    radialGlow(context, center: CGPoint(x: 755, y: 220), radius: 320, glow: color(0xFFD39A, alpha: 0.16))
    radialGlow(context, center: CGPoint(x: 260, y: 820), radius: 360, glow: color(0x8DF0E1, alpha: 0.18))

    let outer = NSBezierPath()
    outer.move(to: CGPoint(x: 720, y: 300))
    outer.curve(
        to: CGPoint(x: 320, y: 745),
        controlPoint1: CGPoint(x: 780, y: 470),
        controlPoint2: CGPoint(x: 605, y: 790)
    )
    outer.curve(
        to: CGPoint(x: 435, y: 305),
        controlPoint1: CGPoint(x: 145, y: 660),
        controlPoint2: CGPoint(x: 180, y: 350)
    )
    outer.curve(
        to: CGPoint(x: 624, y: 496),
        controlPoint1: CGPoint(x: 565, y: 255),
        controlPoint2: CGPoint(x: 675, y: 385)
    )
    outer.curve(
        to: CGPoint(x: 488, y: 612),
        controlPoint1: CGPoint(x: 612, y: 575),
        controlPoint2: CGPoint(x: 546, y: 640)
    )
    strokePath(
        outer,
        color: color(0xF7FAFF, alpha: 0.95),
        width: 70,
        shadow: color(0xB9EFFF, alpha: 0.16).cgColor,
        blur: 16
    )

    let inner = NSBezierPath()
    inner.move(to: CGPoint(x: 622, y: 382))
    inner.curve(
        to: CGPoint(x: 390, y: 600),
        controlPoint1: CGPoint(x: 642, y: 492),
        controlPoint2: CGPoint(x: 515, y: 628)
    )
    inner.curve(
        to: CGPoint(x: 470, y: 410),
        controlPoint1: CGPoint(x: 315, y: 548),
        controlPoint2: CGPoint(x: 335, y: 420)
    )
    inner.curve(
        to: CGPoint(x: 560, y: 498),
        controlPoint1: CGPoint(x: 530, y: 384),
        controlPoint2: CGPoint(x: 578, y: 442)
    )
    strokePath(
        inner,
        color: color(0x8DEEDF, alpha: 0.95),
        width: 24,
        shadow: color(0x8DEEDF, alpha: 0.2).cgColor,
        blur: 10
    )

    drawDot(context, center: CGPoint(x: 512, y: 508), radius: 48, colors: [
        color(0xFFF6DE),
        color(0xFFC87E),
        color(0xFFA060),
    ])

    drawSoftRing(center: CGPoint(x: 512, y: 512), radius: 292, lineWidth: 12, stroke: color(0xFFFFFF, alpha: 0.08))
    context.restoreGState()
    try finishBitmap(bitmap, to: url)
}

func saveHumanArc(to url: URL) throws {
    let (bitmap, context) = makeBitmapContext()
    clipRoundedRect(context)
    backgroundGradient(
        context,
        colors: [color(0x1C1231), color(0x59307B), color(0xA073D5)],
        start: CGPoint(x: 120, y: 1024),
        end: CGPoint(x: 940, y: 0)
    )
    radialGlow(context, center: CGPoint(x: 780, y: 190), radius: 280, glow: color(0xFFD594, alpha: 0.18))
    radialGlow(context, center: CGPoint(x: 280, y: 810), radius: 320, glow: color(0x7EEAD9, alpha: 0.16))

    let body = NSBezierPath()
    body.move(to: CGPoint(x: 516, y: 286))
    body.curve(
        to: CGPoint(x: 700, y: 610),
        controlPoint1: CGPoint(x: 634, y: 310),
        controlPoint2: CGPoint(x: 730, y: 455)
    )
    body.curve(
        to: CGPoint(x: 322, y: 610),
        controlPoint1: CGPoint(x: 640, y: 756),
        controlPoint2: CGPoint(x: 382, y: 756)
    )
    body.curve(
        to: CGPoint(x: 516, y: 286),
        controlPoint1: CGPoint(x: 292, y: 455),
        controlPoint2: CGPoint(x: 398, y: 310)
    )
    color(0xF7F3FF, alpha: 0.95).setFill()
    context.saveGState()
    context.setShadow(offset: .zero, blur: 22, color: color(0xF2E7FF, alpha: 0.15).cgColor)
    body.fill()
    context.restoreGState()

    let innerArc = NSBezierPath()
    innerArc.move(to: CGPoint(x: 420, y: 450))
    innerArc.curve(
        to: CGPoint(x: 603, y: 576),
        controlPoint1: CGPoint(x: 464, y: 540),
        controlPoint2: CGPoint(x: 552, y: 602)
    )
    strokePath(
        innerArc,
        color: color(0x8AEBDD, alpha: 0.92),
        width: 28,
        shadow: color(0x8AEBDD, alpha: 0.18).cgColor,
        blur: 12
    )

    let shoulders = NSBezierPath()
    shoulders.move(to: CGPoint(x: 350, y: 370))
    shoulders.curve(
        to: CGPoint(x: 674, y: 370),
        controlPoint1: CGPoint(x: 430, y: 250),
        controlPoint2: CGPoint(x: 594, y: 250)
    )
    strokePath(
        shoulders,
        color: color(0xF7F3FF, alpha: 0.95),
        width: 52,
        shadow: color(0xFFFFFF, alpha: 0.08).cgColor,
        blur: 14
    )

    drawDot(context, center: CGPoint(x: 512, y: 380), radius: 44, colors: [
        color(0xFFF7E2),
        color(0xFFCD83),
        color(0xFF9F5F),
    ])

    let halo = NSBezierPath(ovalIn: CGRect(x: 232, y: 212, width: 560, height: 560))
    halo.lineWidth = 14
    color(0xFFFFFF, alpha: 0.08).setStroke()
    halo.stroke()

    context.restoreGState()
    try finishBitmap(bitmap, to: url)
}

func saveNeuralBloom(to url: URL) throws {
    let (bitmap, context) = makeBitmapContext()
    clipRoundedRect(context)
    backgroundGradient(
        context,
        colors: [color(0x101F3F), color(0x274E7A), color(0x4E86AA)],
        start: CGPoint(x: 160, y: 980),
        end: CGPoint(x: 900, y: 60)
    )
    radialGlow(context, center: CGPoint(x: 520, y: 520), radius: 300, glow: color(0x92F0E5, alpha: 0.12))
    radialGlow(context, center: CGPoint(x: 800, y: 200), radius: 260, glow: color(0xFFD193, alpha: 0.12))

    let petals: [(CGFloat, NSColor)] = [
        (0, color(0xF4F7FF, alpha: 0.94)),
        (72, color(0xCFE7F8, alpha: 0.88)),
        (144, color(0x98EEDF, alpha: 0.88)),
        (216, color(0xD9F4EE, alpha: 0.88)),
        (288, color(0xF4F7FF, alpha: 0.92)),
    ]

    for (angle, fill) in petals {
        context.saveGState()
        context.translateBy(x: 512, y: 512)
        context.rotate(by: angle * .pi / 180)

        let petal = NSBezierPath()
        petal.move(to: CGPoint(x: 0, y: 44))
        petal.curve(
            to: CGPoint(x: 0, y: 240),
            controlPoint1: CGPoint(x: 92, y: 104),
            controlPoint2: CGPoint(x: 82, y: 210)
        )
        petal.curve(
            to: CGPoint(x: 0, y: 44),
            controlPoint1: CGPoint(x: -82, y: 210),
            controlPoint2: CGPoint(x: -92, y: 104)
        )
        context.setShadow(offset: .zero, blur: 14, color: fill.withAlphaComponent(0.12).cgColor)
        fill.setFill()
        petal.fill()
        context.restoreGState()
    }

    for angle in stride(from: 0, to: 360, by: 60) {
        let radians = CGFloat(angle) * .pi / 180
        let start = CGPoint(x: 512 + cos(radians) * 94, y: 512 + sin(radians) * 94)
        let end = CGPoint(x: 512 + cos(radians) * 250, y: 512 + sin(radians) * 250)
        let line = NSBezierPath()
        line.move(to: start)
        line.line(to: end)
        strokePath(line, color: color(0xDDF7F2, alpha: 0.5), width: 12)
        drawDot(context, center: end, radius: 14, colors: [
            color(0xF9FCFF),
            color(0xCBEAE4),
            color(0x95ECDD),
        ])
    }

    drawDot(context, center: CGPoint(x: 512, y: 512), radius: 64, colors: [
        color(0xFFF6DF),
        color(0xFFCC7E),
        color(0xFFA35D),
    ])

    let ring = NSBezierPath(ovalIn: CGRect(x: 230, y: 230, width: 564, height: 564))
    ring.lineWidth = 12
    color(0xFFFFFF, alpha: 0.07).setStroke()
    ring.stroke()

    context.restoreGState()
    try finishBitmap(bitmap, to: url)
}

let dirURL = URL(fileURLWithPath: outputDir, isDirectory: true)
try FileManager.default.createDirectory(at: dirURL, withIntermediateDirectories: true)

try saveSpiralBreath(to: dirURL.appendingPathComponent("preview_spiral_breath.png"))
try saveHumanArc(to: dirURL.appendingPathComponent("preview_human_arc.png"))
try saveNeuralBloom(to: dirURL.appendingPathComponent("preview_neural_bloom.png"))
