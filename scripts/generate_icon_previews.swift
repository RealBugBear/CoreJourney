import AppKit
import Foundation

let outputDir = CommandLine.arguments.dropFirst().first
    ?? "design/icon_previews"

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

func roundedClip(in context: CGContext, inset: CGFloat = 48, radius: CGFloat = 220) {
    let path = NSBezierPath(
        roundedRect: rect.insetBy(dx: inset, dy: inset),
        xRadius: radius,
        yRadius: radius
    )
    context.saveGState()
    path.addClip()
}

func backgroundGradient(
    _ context: CGContext,
    colors: [NSColor],
    start: CGPoint = CGPoint(x: 100, y: 960),
    end: CGPoint = CGPoint(x: 924, y: 80)
) {
    let gradient = CGGradient(
        colorsSpace: CGColorSpaceCreateDeviceRGB(),
        colors: colors.map(\.cgColor) as CFArray,
        locations: nil
    )!
    context.drawLinearGradient(gradient, start: start, end: end, options: [])
}

func radialGlow(
    _ context: CGContext,
    center: CGPoint,
    radius: CGFloat,
    color glow: NSColor
) {
    let gradient = CGGradient(
        colorsSpace: CGColorSpaceCreateDeviceRGB(),
        colors: [glow.cgColor, glow.withAlphaComponent(0).cgColor] as CFArray,
        locations: [0.0, 1.0]
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

func strokeArc(
    center: CGPoint,
    radius: CGFloat,
    startAngle: CGFloat,
    endAngle: CGFloat,
    lineWidth: CGFloat,
    color stroke: NSColor,
    shadow: CGColor? = nil,
    blur: CGFloat = 0
) {
    let path = NSBezierPath()
    path.appendArc(
        withCenter: center,
        radius: radius,
        startAngle: startAngle,
        endAngle: endAngle,
        clockwise: false
    )
    path.lineWidth = lineWidth
    path.lineCapStyle = .round
    if let shadow {
        NSGraphicsContext.current?.cgContext.saveGState()
        NSGraphicsContext.current?.cgContext.setShadow(offset: .zero, blur: blur, color: shadow)
        stroke.setStroke()
        path.stroke()
        NSGraphicsContext.current?.cgContext.restoreGState()
    } else {
        stroke.setStroke()
        path.stroke()
    }
}

func fillCircle(_ context: CGContext, center: CGPoint, radius: CGFloat, colors: [NSColor]) {
    let gradient = CGGradient(
        colorsSpace: CGColorSpaceCreateDeviceRGB(),
        colors: colors.map(\.cgColor) as CFArray,
        locations: [0.0, 0.55, 1.0]
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

func saveCalmOrbit(to url: URL) throws {
    let (bitmap, context) = makeBitmapContext()
    roundedClip(in: context)
    backgroundGradient(
        context,
        colors: [color(0x0F1738), color(0x27376D), color(0x5D48D7)]
    )
    radialGlow(context, center: CGPoint(x: 250, y: 820), radius: 420, color: color(0x8CF1E4, alpha: 0.22))
    radialGlow(context, center: CGPoint(x: 770, y: 210), radius: 320, color: color(0xFFC78A, alpha: 0.18))

    for (index, alpha) in [0.12, 0.08, 0.05].enumerated() {
        let ring = NSBezierPath(ovalIn: rect.insetBy(dx: CGFloat(176 + index * 76), dy: CGFloat(176 + index * 76)))
        ring.lineWidth = CGFloat(20 - index * 4)
        color(0xFFFFFF, alpha: alpha).setStroke()
        ring.stroke()
    }

    strokeArc(
        center: CGPoint(x: 512, y: 512),
        radius: 246,
        startAngle: 42,
        endAngle: 318,
        lineWidth: 84,
        color: color(0xF7F5FF, alpha: 0.96),
        shadow: color(0xB6A8FF, alpha: 0.28).cgColor,
        blur: 28
    )
    strokeArc(
        center: CGPoint(x: 512, y: 512),
        radius: 132,
        startAngle: 56,
        endAngle: 304,
        lineWidth: 22,
        color: color(0x93EFE0, alpha: 0.92),
        shadow: color(0x93EFE0, alpha: 0.22).cgColor,
        blur: 12
    )

    let path = NSBezierPath()
    path.move(to: CGPoint(x: 614, y: 434))
    path.curve(
        to: CGPoint(x: 518, y: 512),
        controlPoint1: CGPoint(x: 580, y: 434),
        controlPoint2: CGPoint(x: 542, y: 470)
    )
    path.curve(
        to: CGPoint(x: 420, y: 570),
        controlPoint1: CGPoint(x: 488, y: 548),
        controlPoint2: CGPoint(x: 450, y: 576)
    )
    path.lineWidth = 18
    path.lineCapStyle = .round
    context.saveGState()
    context.setShadow(offset: .zero, blur: 10, color: color(0xF4FFFD, alpha: 0.18).cgColor)
    color(0xDFFCF6, alpha: 0.9).setStroke()
    path.stroke()
    context.restoreGState()

    fillCircle(context, center: CGPoint(x: 474, y: 510), radius: 54, colors: [
        color(0xFFF9E7),
        color(0xFFD58C),
        color(0xFFA861),
    ])

    context.restoreGState()
    try finishBitmap(bitmap, to: url)
}

func savePulseMonogram(to url: URL) throws {
    let (bitmap, context) = makeBitmapContext()
    roundedClip(in: context)
    backgroundGradient(
        context,
        colors: [color(0x150F29), color(0x402465), color(0x8663E8)],
        start: CGPoint(x: 120, y: 1024),
        end: CGPoint(x: 950, y: 0)
    )
    radialGlow(context, center: CGPoint(x: 300, y: 760), radius: 360, color: color(0x7AE5D7, alpha: 0.20))

    let diskRect = CGRect(x: 164, y: 164, width: 696, height: 696)
    let disk = NSBezierPath(ovalIn: diskRect)
    color(0xFFFFFF, alpha: 0.09).setFill()
    disk.fill()

    for (scale, alpha) in [(0.0, 0.10), (42.0, 0.07), (84.0, 0.05)] {
        let ringRect = diskRect.insetBy(dx: CGFloat(scale), dy: CGFloat(scale))
        let ring = NSBezierPath(ovalIn: ringRect)
        ring.lineWidth = 16
        color(0xFFFFFF, alpha: CGFloat(alpha)).setStroke()
        ring.stroke()
    }

    strokeArc(
        center: CGPoint(x: 512, y: 512),
        radius: 214,
        startAngle: 42,
        endAngle: 322,
        lineWidth: 70,
        color: color(0xFEFCFF, alpha: 0.96),
        shadow: color(0xF1E6FF, alpha: 0.18).cgColor,
        blur: 18
    )

    let pulse = NSBezierPath()
    pulse.move(to: CGPoint(x: 332, y: 505))
    pulse.line(to: CGPoint(x: 420, y: 505))
    pulse.curve(
        to: CGPoint(x: 500, y: 560),
        controlPoint1: CGPoint(x: 448, y: 505),
        controlPoint2: CGPoint(x: 466, y: 554)
    )
    pulse.curve(
        to: CGPoint(x: 564, y: 458),
        controlPoint1: CGPoint(x: 526, y: 560),
        controlPoint2: CGPoint(x: 540, y: 458)
    )
    pulse.curve(
        to: CGPoint(x: 678, y: 458),
        controlPoint1: CGPoint(x: 590, y: 458),
        controlPoint2: CGPoint(x: 640, y: 458)
    )
    pulse.lineWidth = 28
    pulse.lineCapStyle = .round
    pulse.lineJoinStyle = .round
    context.saveGState()
    context.setShadow(offset: .zero, blur: 14, color: color(0x7BEBDC, alpha: 0.24).cgColor)
    color(0x8EF0E2, alpha: 0.95).setStroke()
    pulse.stroke()
    context.restoreGState()

    fillCircle(context, center: CGPoint(x: 512, y: 512), radius: 42, colors: [
        color(0xFFF8E0),
        color(0xFFC878),
        color(0xFFA35C),
    ])

    context.restoreGState()
    try finishBitmap(bitmap, to: url)
}

func saveNorthStar(to url: URL) throws {
    let (bitmap, context) = makeBitmapContext()
    roundedClip(in: context)
    backgroundGradient(
        context,
        colors: [color(0x0C1B2E), color(0x1D4764), color(0x3A6F9A)],
        start: CGPoint(x: 160, y: 980),
        end: CGPoint(x: 870, y: 80)
    )
    radialGlow(context, center: CGPoint(x: 240, y: 850), radius: 360, color: color(0x82F1E7, alpha: 0.18))
    radialGlow(context, center: CGPoint(x: 800, y: 180), radius: 260, color: color(0xFFD493, alpha: 0.15))

    let medallionRect = CGRect(x: 188, y: 188, width: 648, height: 648)
    let medallion = NSBezierPath(ovalIn: medallionRect)
    color(0xF8FBFF, alpha: 0.10).setFill()
    medallion.fill()

    let medallionStroke = NSBezierPath(ovalIn: medallionRect)
    medallionStroke.lineWidth = 20
    color(0xFFFFFF, alpha: 0.10).setStroke()
    medallionStroke.stroke()

    strokeArc(
        center: CGPoint(x: 512, y: 512),
        radius: 202,
        startAngle: 50,
        endAngle: 310,
        lineWidth: 56,
        color: color(0xF4F8FF, alpha: 0.96),
        shadow: color(0xB8E8FF, alpha: 0.18).cgColor,
        blur: 16
    )

    let vertical = NSBezierPath()
    vertical.move(to: CGPoint(x: 512, y: 358))
    vertical.line(to: CGPoint(x: 512, y: 666))
    vertical.lineWidth = 22
    vertical.lineCapStyle = .round
    color(0xD9FBF5, alpha: 0.90).setStroke()
    vertical.stroke()

    let diagonal = NSBezierPath()
    diagonal.move(to: CGPoint(x: 432, y: 440))
    diagonal.curve(
        to: CGPoint(x: 612, y: 600),
        controlPoint1: CGPoint(x: 486, y: 456),
        controlPoint2: CGPoint(x: 556, y: 588)
    )
    diagonal.lineWidth = 20
    diagonal.lineCapStyle = .round
    color(0x93EFE0, alpha: 0.90).setStroke()
    diagonal.stroke()

    let star = NSBezierPath()
    star.move(to: CGPoint(x: 512, y: 568))
    star.line(to: CGPoint(x: 532, y: 620))
    star.line(to: CGPoint(x: 586, y: 620))
    star.line(to: CGPoint(x: 542, y: 654))
    star.line(to: CGPoint(x: 558, y: 708))
    star.line(to: CGPoint(x: 512, y: 674))
    star.line(to: CGPoint(x: 466, y: 708))
    star.line(to: CGPoint(x: 482, y: 654))
    star.line(to: CGPoint(x: 438, y: 620))
    star.line(to: CGPoint(x: 492, y: 620))
    star.close()
    color(0xFFD889, alpha: 0.95).setFill()
    context.saveGState()
    context.setShadow(offset: .zero, blur: 18, color: color(0xFFD889, alpha: 0.28).cgColor)
    star.fill()
    context.restoreGState()

    context.restoreGState()
    try finishBitmap(bitmap, to: url)
}

let dirURL = URL(fileURLWithPath: outputDir, isDirectory: true)
try FileManager.default.createDirectory(at: dirURL, withIntermediateDirectories: true)

try saveCalmOrbit(to: dirURL.appendingPathComponent("preview_calm_orbit.png"))
try savePulseMonogram(to: dirURL.appendingPathComponent("preview_pulse_monogram.png"))
try saveNorthStar(to: dirURL.appendingPathComponent("preview_north_star.png"))
