import AppKit
import Foundation

let outputPath = CommandLine.arguments.dropFirst().first
    ?? "assets/icon.png"

let canvasSize = CGSize(width: 1024, height: 1024)
let rect = CGRect(origin: .zero, size: canvasSize)

func color(_ hex: Int, alpha: CGFloat = 1) -> NSColor {
    NSColor(
        calibratedRed: CGFloat((hex >> 16) & 0xff) / 255,
        green: CGFloat((hex >> 8) & 0xff) / 255,
        blue: CGFloat(hex & 0xff) / 255,
        alpha: alpha
    )
}

extension NSBezierPath {
    var cgPath: CGPath {
        let path = CGMutablePath()
        var points = [NSPoint](repeating: .zero, count: 3)

        for index in 0..<elementCount {
            switch element(at: index, associatedPoints: &points) {
            case .moveTo:
                path.move(to: points[0])
            case .lineTo:
                path.addLine(to: points[0])
            case .curveTo:
                path.addCurve(to: points[2], control1: points[0], control2: points[1])
            case .closePath:
                path.closeSubpath()
            case .cubicCurveTo:
                path.addCurve(to: points[2], control1: points[0], control2: points[1])
            case .quadraticCurveTo:
                path.addQuadCurve(to: points[1], control: points[0])
            @unknown default:
                break
            }
        }

        return path
    }
}

let bitmap = NSBitmapImageRep(
    bitmapDataPlanes: nil,
    pixelsWide: Int(canvasSize.width),
    pixelsHigh: Int(canvasSize.height),
    bitsPerSample: 8,
    samplesPerPixel: 4,
    hasAlpha: true,
    isPlanar: false,
    colorSpaceName: .deviceRGB,
    bytesPerRow: 0,
    bitsPerPixel: 0
)!

guard let graphicsContext = NSGraphicsContext(bitmapImageRep: bitmap) else {
    fatalError("Unable to acquire graphics context")
}

NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = graphicsContext

let context = graphicsContext.cgContext

context.setAllowsAntialiasing(true)
context.setShouldAntialias(true)

let backgroundPath = NSBezierPath(
    roundedRect: rect.insetBy(dx: 48, dy: 48),
    xRadius: 224,
    yRadius: 224
)
context.saveGState()
backgroundPath.addClip()

let backgroundGradient = CGGradient(
    colorsSpace: CGColorSpaceCreateDeviceRGB(),
    colors: [
        color(0x120B2D).cgColor,
        color(0x241451).cgColor,
        color(0x4F34B6).cgColor,
        color(0x6B4CE6).cgColor,
    ] as CFArray,
    locations: [0.0, 0.28, 0.72, 1.0]
)!
context.drawLinearGradient(
    backgroundGradient,
    start: CGPoint(x: 130, y: 980),
    end: CGPoint(x: 910, y: 90),
    options: []
)

let glowGradient = CGGradient(
    colorsSpace: CGColorSpaceCreateDeviceRGB(),
    colors: [
        color(0x6BE7D8, alpha: 0.55).cgColor,
        color(0x6BE7D8, alpha: 0.0).cgColor,
    ] as CFArray,
    locations: [0.0, 1.0]
)!
context.drawRadialGradient(
    glowGradient,
    startCenter: CGPoint(x: 270, y: 820),
    startRadius: 0,
    endCenter: CGPoint(x: 270, y: 820),
    endRadius: 520,
    options: []
)

let bottomGlowGradient = CGGradient(
    colorsSpace: CGColorSpaceCreateDeviceRGB(),
    colors: [
        color(0xFFCC75, alpha: 0.22).cgColor,
        color(0xFFCC75, alpha: 0.0).cgColor,
    ] as CFArray,
    locations: [0.0, 1.0]
)!
context.drawRadialGradient(
    bottomGlowGradient,
    startCenter: CGPoint(x: 720, y: 180),
    startRadius: 0,
    endCenter: CGPoint(x: 720, y: 180),
    endRadius: 340,
    options: []
)

context.setBlendMode(.screen)
for (index, alpha) in [0.12, 0.08, 0.06].enumerated() {
    let inset = CGFloat(164 + (index * 82))
    let orbitalRect = rect.insetBy(dx: inset, dy: inset + CGFloat(index * 18))
    let orbitalPath = NSBezierPath(ovalIn: orbitalRect)
    orbitalPath.lineWidth = CGFloat(24 - (index * 4))
    color(0xFFFFFF, alpha: alpha).setStroke()
    orbitalPath.stroke()
}

let pulsePath = NSBezierPath()
pulsePath.move(to: CGPoint(x: 245, y: 375))
pulsePath.curve(
    to: CGPoint(x: 400, y: 430),
    controlPoint1: CGPoint(x: 290, y: 350),
    controlPoint2: CGPoint(x: 350, y: 420)
)
pulsePath.curve(
    to: CGPoint(x: 510, y: 368),
    controlPoint1: CGPoint(x: 445, y: 440),
    controlPoint2: CGPoint(x: 468, y: 350)
)
pulsePath.curve(
    to: CGPoint(x: 660, y: 495),
    controlPoint1: CGPoint(x: 560, y: 398),
    controlPoint2: CGPoint(x: 612, y: 470)
)
pulsePath.curve(
    to: CGPoint(x: 800, y: 465),
    controlPoint1: CGPoint(x: 715, y: 522),
    controlPoint2: CGPoint(x: 760, y: 474)
)
pulsePath.lineWidth = 16
pulsePath.lineCapStyle = .round
color(0xD9E8FF, alpha: 0.15).setStroke()
pulsePath.stroke()

context.setBlendMode(.normal)

let outerC = NSBezierPath()
outerC.appendArc(
    withCenter: CGPoint(x: 512, y: 516),
    radius: 250,
    startAngle: 42,
    endAngle: 318,
    clockwise: false
)
outerC.lineWidth = 92
outerC.lineCapStyle = .round
outerC.lineJoinStyle = .round

context.saveGState()
outerC.addClip()
let cGradient = CGGradient(
    colorsSpace: CGColorSpaceCreateDeviceRGB(),
    colors: [
        color(0xFFFFFF).cgColor,
        color(0xE7E3FF).cgColor,
        color(0x91F1E7).cgColor,
    ] as CFArray,
    locations: [0.0, 0.58, 1.0]
)!
context.drawLinearGradient(
    cGradient,
    start: CGPoint(x: 290, y: 760),
    end: CGPoint(x: 745, y: 305),
    options: []
)
context.restoreGState()

context.saveGState()
context.setShadow(offset: .zero, blur: 34, color: color(0xA99CFF, alpha: 0.35).cgColor)
color(0xF6F3FF, alpha: 0.95).setStroke()
outerC.stroke()
context.restoreGState()

let innerC = NSBezierPath()
innerC.appendArc(
    withCenter: CGPoint(x: 512, y: 516),
    radius: 140,
    startAngle: 58,
    endAngle: 302,
    clockwise: false
)
innerC.lineWidth = 26
innerC.lineCapStyle = .round
context.saveGState()
context.setShadow(offset: .zero, blur: 16, color: color(0x6BE7D8, alpha: 0.28).cgColor)
color(0x8FEADD, alpha: 0.92).setStroke()
innerC.stroke()
context.restoreGState()

let path = NSBezierPath()
path.move(to: CGPoint(x: 628, y: 424))
path.curve(
    to: CGPoint(x: 520, y: 506),
    controlPoint1: CGPoint(x: 586, y: 424),
    controlPoint2: CGPoint(x: 550, y: 470)
)
path.curve(
    to: CGPoint(x: 414, y: 560),
    controlPoint1: CGPoint(x: 492, y: 544),
    controlPoint2: CGPoint(x: 448, y: 576)
)
path.lineWidth = 20
path.lineCapStyle = .round
context.saveGState()
context.setShadow(offset: .zero, blur: 14, color: color(0xC8FFF3, alpha: 0.25).cgColor)
color(0xDFFFFA, alpha: 0.95).setStroke()
path.stroke()
context.restoreGState()

let coreCenter = CGPoint(x: 476, y: 524)
let coreRadius: CGFloat = 58
let coreRect = CGRect(
    x: coreCenter.x - coreRadius,
    y: coreCenter.y - coreRadius,
    width: coreRadius * 2,
    height: coreRadius * 2
)
let coreGradient = CGGradient(
    colorsSpace: CGColorSpaceCreateDeviceRGB(),
    colors: [
        color(0xFFF6D6).cgColor,
        color(0xFFD37C).cgColor,
        color(0xFF9A5F).cgColor,
    ] as CFArray,
    locations: [0.0, 0.55, 1.0]
)!
context.saveGState()
context.setShadow(offset: .zero, blur: 28, color: color(0xFFB36C, alpha: 0.42).cgColor)
context.drawRadialGradient(
    coreGradient,
    startCenter: coreCenter,
    startRadius: 4,
    endCenter: coreCenter,
    endRadius: coreRadius,
    options: []
)
context.restoreGState()

let coreHighlight = NSBezierPath(ovalIn: coreRect.insetBy(dx: 10, dy: 10))
color(0xFFFFFF, alpha: 0.18).setStroke()
coreHighlight.lineWidth = 4
coreHighlight.stroke()

let flareCenter = CGPoint(x: 694, y: 640)
let flareRadius: CGFloat = 22
let flareGradient = CGGradient(
    colorsSpace: CGColorSpaceCreateDeviceRGB(),
    colors: [
        color(0xFFFFFF, alpha: 1.0).cgColor,
        color(0xFFFFFF, alpha: 0.0).cgColor,
    ] as CFArray,
    locations: [0.0, 1.0]
)!
context.drawRadialGradient(
    flareGradient,
    startCenter: flareCenter,
    startRadius: 0,
    endCenter: flareCenter,
    endRadius: flareRadius,
    options: []
)

context.restoreGState()
NSGraphicsContext.restoreGraphicsState()

guard let pngData = bitmap.representation(using: .png, properties: [:]) else {
    fatalError("Unable to build PNG representation")
}

let outputURL = URL(fileURLWithPath: outputPath)
try FileManager.default.createDirectory(
    at: outputURL.deletingLastPathComponent(),
    withIntermediateDirectories: true
)
try pngData.write(to: outputURL)
