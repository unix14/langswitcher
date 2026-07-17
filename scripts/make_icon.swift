import Cocoa
import CoreGraphics
import CoreText

func drawText(_ text: String, center: CGPoint, font: NSFont, color: NSColor, in context: CGContext) {
    let attributes: [NSAttributedString.Key: Any] = [
        .font: font,
        .foregroundColor: color
    ]
    let attrString = NSAttributedString(string: text, attributes: attributes)
    let line = CTLineCreateWithAttributedString(attrString)
    var ascent: CGFloat = 0
    var descent: CGFloat = 0
    var leading: CGFloat = 0
    let width = CTLineGetTypographicBounds(line, &ascent, &descent, &leading)
    
    let x = center.x - CGFloat(width) / 2
    let y = center.y - (ascent - descent) / 2
    
    context.textPosition = CGPoint(x: x, y: y)
    CTLineDraw(line, context)
}

func drawArrow(in context: CGContext, cy: CGFloat, cx: CGFloat, span: CGFloat, thick: CGFloat, head: CGFloat, pointingRight: Bool) {
    context.setFillColor(NSColor.white.cgColor)
    
    let arrowLength = span
    let headLength = head
    let halfHeadThick = head * 0.68
    
    if pointingRight {
        let rx = cx + arrowLength / 2
        let lx = cx - arrowLength / 2
        
        let path = CGMutablePath()
        path.move(to: CGPoint(x: rx, y: cy))
        path.addLine(to: CGPoint(x: rx - headLength, y: cy + halfHeadThick))
        path.addLine(to: CGPoint(x: rx - headLength, y: cy - halfHeadThick))
        path.closeSubpath()
        context.addPath(path)
        context.fillPath()
        
        let shaftRect = CGRect(x: lx, y: cy - thick / 2, width: arrowLength - headLength, height: thick)
        context.fill(shaftRect)
    } else {
        let lx = cx - arrowLength / 2
        
        let path = CGMutablePath()
        path.move(to: CGPoint(x: lx, y: cy))
        path.addLine(to: CGPoint(x: lx + headLength, y: cy + halfHeadThick))
        path.addLine(to: CGPoint(x: lx + headLength, y: cy - halfHeadThick))
        path.closeSubpath()
        context.addPath(path)
        context.fillPath()
        
        let shaftRect = CGRect(x: lx + headLength, y: cy - thick / 2, width: arrowLength - headLength, height: thick)
        context.fill(shaftRect)
    }
}

func generateIcon(size: Int) -> CGImage? {
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    guard let context = CGContext(
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
    
    let sizeF = CGFloat(size)
    
    let rectPath = CGPath(
        roundedRect: CGRect(x: 0, y: 0, width: sizeF, height: sizeF),
        cornerWidth: sizeF * 0.22,
        cornerHeight: sizeF * 0.22,
        transform: nil
    )
    
    context.saveGState()
    context.addPath(rectPath)
    context.clip()
    
    let gradientColors = [
        NSColor(red: 0.07, green: 0.07, blue: 0.22, alpha: 1.0).cgColor,
        NSColor(red: 0.20, green: 0.05, blue: 0.38, alpha: 1.0).cgColor
    ] as CFArray
    guard let gradient = CGGradient(colorsSpace: colorSpace, colors: gradientColors, locations: nil) else {
        context.restoreGState()
        return nil
    }
    context.drawLinearGradient(gradient, start: CGPoint(x: 0, y: sizeF), end: CGPoint(x: 0, y: 0), options: [])
    context.restoreGState()
    
    let fontSize = sizeF * 0.31
    let font = NSFont.boldSystemFont(ofSize: fontSize)
    
    drawText(
        "A",
        center: CGPoint(x: sizeF * 0.21, y: sizeF * 0.50),
        font: font,
        color: NSColor(red: 0.45, green: 0.80, blue: 1.00, alpha: 1.0),
        in: context
    )
    
    drawText(
        "א",
        center: CGPoint(x: sizeF * 0.79, y: sizeF * 0.50),
        font: font,
        color: NSColor(red: 1.00, green: 0.76, blue: 0.22, alpha: 1.0),
        in: context
    )
    
    if size >= 32 {
        let span = sizeF * 0.21
        let thick = max(2.0, sizeF * 0.056)
        let head = sizeF * 0.092
        let cx = sizeF * 0.50
        
        drawArrow(in: context, cy: sizeF * 0.615, cx: cx, span: span, thick: thick, head: head, pointingRight: true)
        drawArrow(in: context, cy: sizeF * 0.385, cx: cx, span: span, thick: thick, head: head, pointingRight: false)
    }
    
    return context.makeImage()
}

func savePNG(image: CGImage, url: URL) {
    let rep = NSBitmapImageRep(cgImage: image)
    guard let data = rep.representation(using: .png, properties: [:]) else {
        print("Failed to get PNG representation for image")
        return
    }
    do {
        try data.write(to: url)
    } catch {
        print("Failed to write image to \(url.path): \(error)")
    }
}

// 1. Prepare directories
let fm = FileManager.default
let currentDir = fm.currentDirectoryPath
let appIconSetPath = "\(currentDir)/LangSwitcher/Assets.xcassets/AppIcon.appiconset"
let iconsetPath = "\(currentDir)/LangSwitcher.iconset"

try? fm.createDirectory(atPath: appIconSetPath, withIntermediateDirectories: true, attributes: nil)
try? fm.createDirectory(atPath: iconsetPath, withIntermediateDirectories: true, attributes: nil)

let iconSizes = [
    (16,   "icon_16x16.png",       "icon_16x16.png"),
    (32,   "icon_16x16@2x.png",    "icon_16x16@2x.png"),
    (32,   "icon_32x32.png",       "icon_32x32.png"),
    (64,   "icon_32x32@2x.png",    "icon_32x32@2x.png"),
    (128,  "icon_128x128.png",     "icon_128x128.png"),
    (256,  "icon_128x128@2x.png",  "icon_128x128@2x.png"),
    (256,  "icon_256x256.png",     "icon_256x256.png"),
    (512,  "icon_256x256@2x.png",  "icon_256x256@2x.png"),
    (512,  "icon_512x512.png",     "icon_512x512.png"),
    (1024, "icon_512x512@2x.png",  "icon_512x512@2x.png")
]

print("▶ Generating icons...")
for (size, iconsetName, appIconSetName) in iconSizes {
    guard let image = generateIcon(size: size) else {
        print("Failed to generate icon of size \(size)")
        continue
    }
    
    // Save to temp iconset folder
    let iconsetUrl = URL(fileURLWithPath: "\(iconsetPath)/\(iconsetName)")
    savePNG(image: image, url: iconsetUrl)
    
    // Save to Assets appiconset folder
    let appIconSetUrl = URL(fileURLWithPath: "\(appIconSetPath)/\(appIconSetName)")
    savePNG(image: image, url: appIconSetUrl)
}

// 2. Write Contents.json
let contentsJson = """
{
  "images" : [
    {
      "idiom" : "mac",
      "size" : "16x16",
      "scale" : "1x",
      "filename" : "icon_16x16.png"
    },
    {
      "idiom" : "mac",
      "size" : "16x16",
      "scale" : "2x",
      "filename" : "icon_16x16@2x.png"
    },
    {
      "idiom" : "mac",
      "size" : "32x32",
      "scale" : "1x",
      "filename" : "icon_32x32.png"
    },
    {
      "idiom" : "mac",
      "size" : "32x32",
      "scale" : "2x",
      "filename" : "icon_32x32@2x.png"
    },
    {
      "idiom" : "mac",
      "size" : "128x128",
      "scale" : "1x",
      "filename" : "icon_128x128.png"
    },
    {
      "idiom" : "mac",
      "size" : "128x128",
      "scale" : "2x",
      "filename" : "icon_128x128@2x.png"
    },
    {
      "idiom" : "mac",
      "size" : "256x256",
      "scale" : "1x",
      "filename" : "icon_256x256.png"
    },
    {
      "idiom" : "mac",
      "size" : "256x256",
      "scale" : "2x",
      "filename" : "icon_256x256@2x.png"
    },
    {
      "idiom" : "mac",
      "size" : "512x512",
      "scale" : "1x",
      "filename" : "icon_512x512.png"
    },
    {
      "idiom" : "mac",
      "size" : "512x512",
      "scale" : "2x",
      "filename" : "icon_512x512@2x.png"
    }
  ],
  "info" : {
    "version" : 1,
    "author" : "xcode"
  }
}
"""

let contentsJsonUrl = URL(fileURLWithPath: "\(appIconSetPath)/Contents.json")
try? contentsJson.write(to: contentsJsonUrl, atomically: true, encoding: .utf8)
print("✓ Contents.json generated")

// 3. Compile to .icns using iconutil
print("▶ Compiling .icns...")
let task = Process()
task.launchPath = "/usr/bin/iconutil"
task.arguments = ["-c", "icns", iconsetPath, "-o", "\(currentDir)/LangSwitcher/LangSwitcher.icns"]
task.launch()
task.waitUntilExit()

if task.terminationStatus == 0 {
    print("✓ LangSwitcher.icns successfully compiled")
} else {
    print("✗ Failed to compile icns (iconutil exit status: \(task.terminationStatus))")
}

// Cleanup iconset directory
try? fm.removeItem(atPath: iconsetPath)
print("✓ Temporary iconset directory removed")
