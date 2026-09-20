#!/usr/bin/env swift

import Cocoa
import CoreGraphics
import CoreText

func generateRatexIcon(canvasSize: CGFloat = 1024) -> NSImage {
    let scale = canvasSize / 1024.0
    let img = NSImage(size: NSSize(width: canvasSize, height: canvasSize))
    img.lockFocus()
    
    guard let ctx = NSGraphicsContext.current?.cgContext else {
        img.unlockFocus()
        return img
    }
    
    ctx.setAllowsAntialiasing(true)
    ctx.setShouldAntialias(true)
    ctx.interpolationQuality = .high
    
    // Apple macOS Standard Icon Grid (1024x1024 base):
    // Squircle size: 824 x 824 pt centered horizontally at x=100, y=114
    let squircleRect = CGRect(x: 100 * scale, y: 114 * scale, width: 824 * scale, height: 824 * scale)
    let cornerRadius = 185.0 * scale
    let squirclePath = CGPath(roundedRect: squircleRect, cornerWidth: cornerRadius, cornerHeight: cornerRadius, transform: nil)
    
    // 1. APPLE STANDARD DROP SHADOWS
    // 1a. Ambient floor shadow
    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: -18 * scale), blur: 28 * scale, color: CGColor(red: 0, green: 0, blue: 0, alpha: 0.35))
    ctx.setFillColor(CGColor(red: 0, green: 0, blue: 0, alpha: 0.35))
    ctx.addPath(squirclePath)
    ctx.fillPath()
    
    // 1b. Direct key shadow
    ctx.setShadow(offset: CGSize(width: 0, height: -32 * scale), blur: 44 * scale, color: CGColor(red: 0, green: 0, blue: 0, alpha: 0.24))
    ctx.setFillColor(CGColor(red: 0, green: 0, blue: 0, alpha: 0.24))
    ctx.addPath(squirclePath)
    ctx.fillPath()
    ctx.restoreGState()
    
    // 2. SQUIRCLE BODY CLIP
    ctx.saveGState()
    ctx.addPath(squirclePath)
    ctx.clip()
    
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    
    // 2a. Background Base Gradient (Dark Slate Titanium / Matte Obsidian)
    let bgColors = [
        CGColor(red: 0.27, green: 0.30, blue: 0.35, alpha: 1.0), // Top: #454D59
        CGColor(red: 0.18, green: 0.20, blue: 0.24, alpha: 1.0), // Mid: #2E333D
        CGColor(red: 0.11, green: 0.12, blue: 0.15, alpha: 1.0)  // Bottom: #1C1F26
    ] as CFArray
    let bgLocations: [CGFloat] = [0.0, 0.45, 1.0]
    if let bgGradient = CGGradient(colorsSpace: colorSpace, colors: bgColors, locations: bgLocations) {
        ctx.drawLinearGradient(bgGradient,
                               start: CGPoint(x: squircleRect.midX, y: squircleRect.maxY),
                               end: CGPoint(x: squircleRect.midX, y: squircleRect.minY),
                               options: [])
    }
    
    // 2b. Smooth top illumination
    ctx.saveGState()
    let radColors = [
        CGColor(red: 0.40, green: 0.45, blue: 0.52, alpha: 0.30),
        CGColor(red: 0.20, green: 0.22, blue: 0.26, alpha: 0.0)
    ] as CFArray
    if let radGrad = CGGradient(colorsSpace: colorSpace, colors: radColors, locations: [0.0, 1.0]) {
        ctx.drawRadialGradient(radGrad,
                               startCenter: CGPoint(x: squircleRect.midX, y: squircleRect.maxY),
                               startRadius: 0,
                               endCenter: CGPoint(x: squircleRect.midX, y: squircleRect.midY),
                               endRadius: 520 * scale,
                               options: [.drawsAfterEndLocation])
    }
    ctx.restoreGState()
    
    // 3. THE EMBLEM: SERIF "R"
    let font = NSFont(name: "TimesNewRomanPS-BoldMT", size: 600.0 * scale) ?? NSFont.boldSystemFont(ofSize: 600.0 * scale)
    let attrStr = NSAttributedString(string: "R", attributes: [.font: font])
    let line = CTLineCreateWithAttributedString(attrStr)
    let runs = CTLineGetGlyphRuns(line)
    let rawPath = CGMutablePath()
    
    for i in 0..<CFArrayGetCount(runs) {
        let run = unsafeBitCast(CFArrayGetValueAtIndex(runs, i), to: CTRun.self)
        let runFont = unsafeBitCast(CFDictionaryGetValue(CTRunGetAttributes(run), Unmanaged.passUnretained(kCTFontAttributeName).toOpaque()), to: CTFont.self)
        let count = CTRunGetGlyphCount(run)
        for j in 0..<count {
            var g = CGGlyph()
            var p = CGPoint()
            CTRunGetGlyphs(run, CFRangeMake(j, 1), &g)
            CTRunGetPositions(run, CFRangeMake(j, 1), &p)
            if let glyphP = CTFontCreatePathForGlyph(runFont, g, nil) {
                let t = CGAffineTransform(translationX: p.x, y: p.y)
                rawPath.addPath(glyphP, transform: t)
            }
        }
    }
    
    let rawBounds = rawPath.boundingBox
    let targetX = squircleRect.midX - rawBounds.midX
    let targetY = squircleRect.midY - rawBounds.midY
    var centerTransform = CGAffineTransform(translationX: targetX, y: targetY)
    guard let rPath = rawPath.copy(using: &centerTransform) else {
        img.unlockFocus()
        return img
    }
    let rBounds = rPath.boundingBox
    
    // 3a. Deep Ambient Shadow of "R" onto the tile
    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: -18 * scale), blur: 28 * scale, color: CGColor(red: 0, green: 0, blue: 0, alpha: 0.70))
    ctx.setFillColor(CGColor(red: 0, green: 0, blue: 0, alpha: 0.70))
    ctx.addPath(rPath)
    ctx.fillPath()
    
    ctx.setShadow(offset: CGSize(width: 0, height: -6 * scale), blur: 12 * scale, color: CGColor(red: 0, green: 0, blue: 0, alpha: 0.65))
    ctx.setFillColor(CGColor(red: 0, green: 0, blue: 0, alpha: 0.65))
    ctx.addPath(rPath)
    ctx.fillPath()
    ctx.restoreGState()
    
    // 3b. 3D Bevel Extrusion for the "R"
    ctx.saveGState()
    let bevelLayers = Int(14 * scale)
    for step in 1...bevelLayers {
        let yOffset = -CGFloat(step) * 0.9
        var bevelT = CGAffineTransform(translationX: 0, y: yOffset)
        if let offsetPath = rPath.copy(using: &bevelT) {
            ctx.addPath(offsetPath)
            ctx.setFillColor(CGColor(red: 0.35, green: 0.04, blue: 0.07, alpha: 0.70))
            ctx.fillPath()
        }
    }
    ctx.restoreGState()
    
    // 3c. Face Fill of the "R": Rich Crimson / Carmine / Ruby Gradient
    ctx.saveGState()
    ctx.addPath(rPath)
    ctx.clip()
    
    let rColors = [
        CGColor(red: 0.76, green: 0.18, blue: 0.22, alpha: 1.0), // Top: #C22E38
        CGColor(red: 0.60, green: 0.10, blue: 0.14, alpha: 1.0), // Mid: #991A24
        CGColor(red: 0.42, green: 0.04, blue: 0.07, alpha: 1.0)  // Bottom: #6B0A12
    ] as CFArray
    let rLocations: [CGFloat] = [0.0, 0.45, 1.0]
    if let rGrad = CGGradient(colorsSpace: colorSpace, colors: rColors, locations: rLocations) {
        ctx.drawLinearGradient(rGrad,
                               start: CGPoint(x: squircleRect.midX, y: rBounds.maxY),
                               end: CGPoint(x: squircleRect.midX, y: rBounds.minY),
                               options: [])
    }
    
    // 3d. Subtle top specular highlight on the face of "R"
    ctx.setBlendMode(.screen)
    let specColors = [
        CGColor(red: 1.0, green: 0.65, blue: 0.70, alpha: 0.40),
        CGColor(red: 1.0, green: 0.65, blue: 0.70, alpha: 0.0)
    ] as CFArray
    if let specGrad = CGGradient(colorsSpace: colorSpace, colors: specColors, locations: [0.0, 1.0]) {
        ctx.drawLinearGradient(specGrad,
                               start: CGPoint(x: squircleRect.midX, y: rBounds.maxY),
                               end: CGPoint(x: squircleRect.midX, y: rBounds.maxY - rBounds.height * 0.45),
                               options: [])
    }
    ctx.restoreGState()
    
    // 3e. Crisp Inner Chamfer / Stroke on the "R"
    ctx.saveGState()
    ctx.setLineWidth(1.8 * scale)
    ctx.setStrokeColor(CGColor(red: 1.0, green: 0.55, blue: 0.60, alpha: 0.32))
    ctx.addPath(rPath)
    ctx.strokePath()
    ctx.restoreGState()
    
    // 4. CLEAN NATIVE SQUIRCLE RIM (Top specular glass highlight)
    ctx.saveGState()
    let innerRimPath = CGPath(roundedRect: squircleRect.insetBy(dx: 1.0 * scale, dy: 1.0 * scale),
                              cornerWidth: cornerRadius - 1.0 * scale,
                              cornerHeight: cornerRadius - 1.0 * scale,
                              transform: nil)
    ctx.addPath(innerRimPath)
    ctx.setLineWidth(1.5 * scale)
    ctx.setStrokeColor(CGColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.18))
    ctx.strokePath()
    ctx.restoreGState()
    
    ctx.restoreGState() // Pop squircle clip
    
    img.unlockFocus()
    return img
}

func savePNG(image: NSImage, targetPixelSize: Int, to url: URL) {
    let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: targetPixelSize,
        pixelsHigh: targetPixelSize,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    )!
    
    NSGraphicsContext.saveGraphicsState()
    let ctx = NSGraphicsContext(bitmapImageRep: rep)!
    NSGraphicsContext.current = ctx
    ctx.cgContext.interpolationQuality = .high
    ctx.cgContext.setShouldAntialias(true)
    
    image.draw(in: NSRect(x: 0, y: 0, width: targetPixelSize, height: targetPixelSize),
               from: NSRect(x: 0, y: 0, width: image.size.width, height: image.size.height),
               operation: .copy,
               fraction: 1.0)
    
    NSGraphicsContext.restoreGraphicsState()
    
    guard let pngData = rep.representation(using: .png, properties: [:]) else {
        fatalError("Failed to convert to PNG")
    }
    try! pngData.write(to: url)
}

let scriptDir = URL(fileURLWithPath: CommandLine.arguments[0]).deletingLastPathComponent().path
let baseDir = NSString(string: "\(scriptDir)/../RatexEditor/Resources").standardizingPath
let xcassetDir = "\(baseDir)/Assets.xcassets/AppIcon.appiconset"
let tmpIconsetDir = "/tmp/RatexAppIcon.iconset"

let fm = FileManager.default
try? fm.removeItem(atPath: tmpIconsetDir)
try! fm.createDirectory(atPath: tmpIconsetDir, withIntermediateDirectories: true, attributes: nil)

print("Generating 2048x2048 master image...")
let masterIcon = generateRatexIcon(canvasSize: 2048)

print("Saving AppIcon.png (1024x1024)...")
savePNG(image: masterIcon, targetPixelSize: 1024, to: URL(fileURLWithPath: "\(baseDir)/AppIcon.png"))

let sizes: [(filename: String, iconsetName: String, px: Int)] = [
    ("icon_16x16.png", "icon_16x16.png", 16),
    ("icon_16x16@2x.png", "icon_16x16@2x.png", 32),
    ("icon_32x32.png", "icon_32x32.png", 32),
    ("icon_32x32@2x.png", "icon_32x32@2x.png", 64),
    ("icon_128x128.png", "icon_128x128.png", 128),
    ("icon_128x128@2x.png", "icon_128x128@2x.png", 256),
    ("icon_256x256.png", "icon_256x256.png", 256),
    ("icon_256x256@2x.png", "icon_256x256@2x.png", 512),
    ("icon_512x512.png", "icon_512x512.png", 512),
    ("icon_512x512@2x.png", "icon_512x512@2x.png", 1024)
]

for item in sizes {
    let xcPath = "\(xcassetDir)/\(item.filename)"
    let iconsetPath = "\(tmpIconsetDir)/\(item.iconsetName)"
    savePNG(image: masterIcon, targetPixelSize: item.px, to: URL(fileURLWithPath: xcPath))
    savePNG(image: masterIcon, targetPixelSize: item.px, to: URL(fileURLWithPath: iconsetPath))
}

print("Compiling AppIcon.icns...")
let icnsPath = "\(baseDir)/AppIcon.icns"
let process = Process()
process.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
process.arguments = ["-c", "icns", tmpIconsetDir, "-o", icnsPath]
try! process.run()
process.waitUntilExit()

if process.terminationStatus == 0 {
    print("Successfully built AppIcon.icns!")
} else {
    print("iconutil failed with code \(process.terminationStatus)")
}

try? fm.removeItem(atPath: tmpIconsetDir)
