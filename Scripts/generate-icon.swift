import AppKit
import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

let outputPaths = CommandLine.arguments.dropFirst()
let resolvedOutputs = outputPaths.isEmpty ? ["Sources/Resources/AppIcon.png"] : Array(outputPaths)
let baseSize = CGSize(width: 1024, height: 1024)

let colorSpace = CGColorSpaceCreateDeviceRGB()
guard let context = CGContext(
    data: nil,
    width: Int(baseSize.width),
    height: Int(baseSize.height),
    bitsPerComponent: 8,
    bytesPerRow: 0,
    space: colorSpace,
    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
) else {
    exit(1)
}

context.setAllowsAntialiasing(true)
context.setShouldAntialias(true)

let backgroundRect = CGRect(origin: .zero, size: baseSize)
let gradientColors = [
    NSColor(calibratedRed: 0.10, green: 0.23, blue: 0.35, alpha: 1.0).cgColor,
    NSColor(calibratedRed: 0.13, green: 0.49, blue: 0.45, alpha: 1.0).cgColor
]
let gradient = CGGradient(colorsSpace: colorSpace, colors: gradientColors as CFArray, locations: [0.0, 1.0])!
context.drawLinearGradient(
    gradient,
    start: CGPoint(x: 0, y: baseSize.height),
    end: CGPoint(x: baseSize.width, y: 0),
    options: []
)

func drawRoundedRect(_ rect: CGRect, radius: CGFloat, fill: NSColor, stroke: NSColor?, lineWidth: CGFloat) {
    let path = CGPath(roundedRect: rect, cornerWidth: radius, cornerHeight: radius, transform: nil)
    context.addPath(path)
    context.setFillColor(fill.cgColor)
    context.fillPath()
    if let stroke = stroke {
        context.addPath(path)
        context.setStrokeColor(stroke.cgColor)
        context.setLineWidth(lineWidth)
        context.strokePath()
    }
}

let paperRect = CGRect(x: 220, y: 140, width: 584, height: 744)
drawRoundedRect(
    paperRect,
    radius: 64,
    fill: NSColor(calibratedWhite: 0.98, alpha: 1.0),
    stroke: NSColor(calibratedWhite: 0.85, alpha: 1.0),
    lineWidth: 12
)

let clipRect = CGRect(x: 380, y: 780, width: 264, height: 120)
drawRoundedRect(
    clipRect,
    radius: 36,
    fill: NSColor(calibratedWhite: 0.20, alpha: 1.0),
    stroke: nil,
    lineWidth: 0
)

let plusCircleRect = CGRect(x: 640, y: 220, width: 180, height: 180)
context.setFillColor(NSColor(calibratedRed: 0.18, green: 0.65, blue: 0.35, alpha: 1.0).cgColor)
context.fillEllipse(in: plusCircleRect)

context.setStrokeColor(NSColor.white.cgColor)
context.setLineWidth(22)
let plusCenter = CGPoint(x: plusCircleRect.midX, y: plusCircleRect.midY)
context.move(to: CGPoint(x: plusCenter.x - 48, y: plusCenter.y))
context.addLine(to: CGPoint(x: plusCenter.x + 48, y: plusCenter.y))
context.move(to: CGPoint(x: plusCenter.x, y: plusCenter.y - 48))
context.addLine(to: CGPoint(x: plusCenter.x, y: plusCenter.y + 48))
context.strokePath()

guard let baseImage = context.makeImage() else {
    exit(1)
}

func makeScaledImage(size: Int, from image: CGImage) -> CGImage? {
    let dimension = CGFloat(size)
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    guard let scaledContext = CGContext(
        data: nil,
        width: size,
        height: size,
        bitsPerComponent: 8,
        bytesPerRow: 0,
        space: colorSpace,
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    ) else {
        return nil
    }
    scaledContext.interpolationQuality = .high
    scaledContext.draw(image, in: CGRect(x: 0, y: 0, width: dimension, height: dimension))
    return scaledContext.makeImage()
}

func writePNG(_ image: CGImage, to url: URL) -> Bool {
    guard let destination = CGImageDestinationCreateWithURL(
        url as CFURL,
        UTType.png.identifier as CFString,
        1,
        nil
    ) else {
        return false
    }
    CGImageDestinationAddImage(destination, image, nil)
    return CGImageDestinationFinalize(destination)
}

for outputPath in resolvedOutputs {
    let outputURL = URL(fileURLWithPath: outputPath)
    let ext = outputURL.pathExtension.lowercased()

    if ext == "iconset" {
        let fileManager = FileManager.default
        try? fileManager.createDirectory(at: outputURL, withIntermediateDirectories: true, attributes: nil)
        let mappings: [(Int, String)] = [
            (16, "icon_16x16.png"),
            (32, "icon_16x16@2x.png"),
            (32, "icon_32x32.png"),
            (64, "icon_32x32@2x.png"),
            (128, "icon_128x128.png"),
            (256, "icon_128x128@2x.png"),
            (256, "icon_256x256.png"),
            (512, "icon_256x256@2x.png"),
            (512, "icon_512x512.png"),
            (1024, "icon_512x512@2x.png")
        ]
        for (size, name) in mappings {
            guard let image = makeScaledImage(size: size, from: baseImage) else { exit(1) }
            let url = outputURL.appendingPathComponent(name)
            if !writePNG(image, to: url) {
                exit(1)
            }
        }
        continue
    }

    if ext == "png" {
        if !writePNG(baseImage, to: outputURL) {
            exit(1)
        }
        continue
    }

    let outputType: UTType = (ext == "icns") ? .icns : .png
    guard let destination = CGImageDestinationCreateWithURL(
        outputURL as CFURL,
        outputType.identifier as CFString,
        1,
        nil
    ) else {
        exit(1)
    }
    CGImageDestinationAddImage(destination, baseImage, nil)
    if !CGImageDestinationFinalize(destination) {
        exit(1)
    }
}
