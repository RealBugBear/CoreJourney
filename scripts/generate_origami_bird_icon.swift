import AppKit
import Foundation

let appIconPath = CommandLine.arguments.dropFirst().first
    ?? "assets/icon.png"
let markPath = CommandLine.arguments.dropFirst().dropFirst().first
    ?? "assets/images/brand/origami_bird_mark.png"

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

struct Facet {
    let points: [CGPoint]
    let fill: NSColor
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

func writeBitmap(_ bitmap: NSBitmapImageRep, to outputPath: String) throws {
    NSGraphicsContext.restoreGraphicsState()
    guard let pngData = bitmap.representation(using: .png, properties: [:]) else {
        fatalError("Unable to encode PNG")
    }
    let outputURL = URL(fileURLWithPath: outputPath)
    try FileManager.default.createDirectory(
        at: outputURL.deletingLastPathComponent(),
        withIntermediateDirectories: true
    )
    try pngData.write(to: outputURL)
}

func radialGlow(_ context: CGContext, center: CGPoint, radius: CGFloat, color glow: NSColor) {
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

func polygonPath(_ points: [CGPoint]) -> NSBezierPath {
    let path = NSBezierPath()
    guard let first = points.first else { return path }
    path.move(to: first)
    for point in points.dropFirst() {
        path.line(to: point)
    }
    path.close()
    return path
}

func strokePolyline(_ points: [CGPoint], width: CGFloat, color stroke: NSColor, alpha: CGFloat = 1.0) {
    let path = NSBezierPath()
    guard let first = points.first else { return }
    path.move(to: first)
    for point in points.dropFirst() {
        path.line(to: point)
    }
    path.lineWidth = width
    path.lineJoinStyle = .round
    path.lineCapStyle = .round
    stroke.withAlphaComponent(alpha).setStroke()
    path.stroke()
}

func drawFacets(_ facets: [Facet], shadow: CGColor? = nil, blur: CGFloat = 0) {
    let context = NSGraphicsContext.current!.cgContext
    if let shadow {
        context.saveGState()
        context.setShadow(offset: CGSize(width: 0, height: -4), blur: blur, color: shadow)
    }
    for facet in facets {
        facet.fill.setFill()
        polygonPath(facet.points).fill()
    }
    if shadow != nil {
        context.restoreGState()
    }
}

func origamiBirdFacets(scale: CGFloat = 1.0, offset: CGPoint = .zero) -> [Facet] {
    func pt(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
        CGPoint(x: x * scale + offset.x, y: y * scale + offset.y)
    }

    return [
        Facet(points: [pt(160, 560), pt(342, 516), pt(276, 650)], fill: color(0x279E73)),
        Facet(points: [pt(160, 560), pt(248, 444), pt(342, 516)], fill: color(0x6CD1A5)),
        Facet(points: [pt(248, 444), pt(470, 520), pt(342, 516)], fill: color(0x0D8A63)),
        Facet(points: [pt(248, 444), pt(414, 350), pt(470, 520)], fill: color(0x37B883)),
        Facet(points: [pt(414, 350), pt(576, 458), pt(470, 520)], fill: color(0x149A6B)),
        Facet(points: [pt(414, 350), pt(620, 352), pt(576, 458)], fill: color(0x88DFC0)),
        Facet(points: [pt(620, 352), pt(756, 446), pt(576, 458)], fill: color(0x4DC892)),
        Facet(points: [pt(576, 458), pt(756, 446), pt(648, 556)], fill: color(0x17A06F)),
        Facet(points: [pt(470, 520), pt(576, 458), pt(648, 556)], fill: color(0x52CB98)),
        Facet(points: [pt(470, 520), pt(648, 556), pt(520, 610)], fill: color(0x0C7E5B)),
        Facet(points: [pt(342, 516), pt(470, 520), pt(520, 610)], fill: color(0x31B27E)),
        Facet(points: [pt(342, 516), pt(520, 610), pt(396, 666)], fill: color(0x8BE2C3)),
        Facet(points: [pt(342, 516), pt(396, 666), pt(276, 650)], fill: color(0x14986A)),
        Facet(points: [pt(520, 610), pt(468, 778), pt(566, 730)], fill: color(0x41C289)),
        Facet(points: [pt(468, 778), pt(514, 876), pt(548, 772)], fill: color(0x0D8A63)),
        Facet(points: [pt(468, 778), pt(548, 772), pt(566, 730)], fill: color(0x79D9B4)),
        Facet(points: [pt(620, 352), pt(694, 328), pt(756, 446)], fill: color(0x17A773)),
        Facet(points: [pt(694, 328), pt(804, 390), pt(756, 446)], fill: color(0xB8F0D9)),
    ]
}

func drawOrigamiBird(scale: CGFloat, offset: CGPoint, shadow: Bool) {
    let facets = origamiBirdFacets(scale: scale, offset: offset)
    drawFacets(
        facets,
        shadow: shadow ? color(0x052B1F, alpha: 0.20).cgColor : nil,
        blur: shadow ? 18 : 0
    )

    let overlayColor = color(0xFFFFFF, alpha: 0.14)
    strokePolyline(
        [
            CGPoint(x: 248 * scale + offset.x, y: 444 * scale + offset.y),
            CGPoint(x: 470 * scale + offset.x, y: 520 * scale + offset.y),
            CGPoint(x: 648 * scale + offset.x, y: 556 * scale + offset.y),
        ],
        width: max(2, 10 * scale),
        color: overlayColor
    )
    strokePolyline(
        [
            CGPoint(x: 414 * scale + offset.x, y: 350 * scale + offset.y),
            CGPoint(x: 576 * scale + offset.x, y: 458 * scale + offset.y),
            CGPoint(x: 520 * scale + offset.x, y: 610 * scale + offset.y),
            CGPoint(x: 468 * scale + offset.x, y: 778 * scale + offset.y),
        ],
        width: max(2, 8 * scale),
        color: overlayColor
    )
}

func renderTransparentMark() throws {
    let (bitmap, context) = makeBitmapContext()
    context.clear(rect)
    radialGlow(context, center: CGPoint(x: 510, y: 540), radius: 220, color: color(0x00C882, alpha: 0.08))
    drawOrigamiBird(scale: 1.05, offset: CGPoint(x: 90, y: 40), shadow: false)
    try writeBitmap(bitmap, to: markPath)
}

func renderAppIcon() throws {
    let (bitmap, context) = makeBitmapContext()

    let clipPath = NSBezierPath(
        roundedRect: rect.insetBy(dx: 52, dy: 52),
        xRadius: 228,
        yRadius: 228
    )
    context.saveGState()
    clipPath.addClip()

    let background = CGGradient(
        colorsSpace: CGColorSpaceCreateDeviceRGB(),
        colors: [
            color(0x0A231A).cgColor,
            color(0x0B4A35).cgColor,
            color(0x009E6B).cgColor,
            color(0x79DDB4).cgColor,
        ] as CFArray,
        locations: [0.0, 0.34, 0.72, 1.0]
    )!
    context.drawLinearGradient(
        background,
        start: CGPoint(x: 90, y: 960),
        end: CGPoint(x: 930, y: 80),
        options: []
    )

    radialGlow(context, center: CGPoint(x: 265, y: 840), radius: 260, color: color(0xCBF8E6, alpha: 0.12))
    radialGlow(context, center: CGPoint(x: 790, y: 200), radius: 300, color: color(0xE9FFF5, alpha: 0.10))

    let plate = NSBezierPath(
        roundedRect: CGRect(x: 178, y: 160, width: 668, height: 704),
        xRadius: 206,
        yRadius: 206
    )
    color(0xFFFFFF, alpha: 0.05).setFill()
    plate.fill()
    plate.lineWidth = 8
    color(0xFFFFFF, alpha: 0.08).setStroke()
    plate.stroke()

    context.saveGState()
    context.setShadow(offset: CGSize(width: 0, height: -8), blur: 28, color: color(0x06261B, alpha: 0.22).cgColor)
    drawOrigamiBird(scale: 0.88, offset: CGPoint(x: 156, y: 170), shadow: false)
    context.restoreGState()

    context.restoreGState()
    try writeBitmap(bitmap, to: appIconPath)
}

try renderTransparentMark()
try renderAppIcon()
