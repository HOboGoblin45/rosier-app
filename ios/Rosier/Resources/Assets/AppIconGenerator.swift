#!/usr/bin/env swift

import Foundation
import CoreGraphics

#if os(macOS)
import AppKit
typealias NSUIImage = NSImage
#else
import UIKit
typealias NSUIImage = UIImage
#endif

// MARK: - Configuration

let appName = "Rosier"
let brandPrimary = CGColor(red: 26/255, green: 26/255, blue: 46/255, alpha: 1.0)  // #1A1A2E
let brandAccent = CGColor(red: 196/255, green: 167/255, blue: 125/255, alpha: 1.0) // #C4A77D

// Icon sizes: (size, scale)
let iconSizes: [(CGFloat, String)] = [
    (20, "20@1x"),
    (40, "20@2x"),
    (60, "20@3x"),
    (29, "29@1x"),
    (58, "29@2x"),
    (87, "29@3x"),
    (40, "40@1x"),
    (80, "40@2x"),
    (120, "40@3x"),
    (76, "76@1x"),
    (152, "76@2x"),
    (167, "76@3x"),  // iPad Pro
    (180, "60@3x"),  // iPhone 6 Plus, 7 Plus, 8 Plus, XR
    (120, "60@2x"),  // iPhone 6, 7, 8
    (1024, "1024@1x") // App Store
]

// MARK: - Icon Renderer

func generateAppIcon(size: CGFloat) -> NSUIImage? {
    let rect = CGRect(x: 0, y: 0, width: size, height: size)

    #if os(macOS)
    let image = NSImage(size: CGSize(width: size, height: size))
    image.lockFocus()
    defer { image.unlockFocus() }
    #else
    UIGraphicsBeginImageContextWithOptions(CGSize(width: size, height: size), true, 0)
    defer { UIGraphicsEndImageContext() }
    #endif

    guard let context = NSGraphicsContext.current?.cgContext else { return nil }

    // Draw gradient background
    drawGradientBackground(context: context, rect: rect)

    // Draw "R" letterform
    drawRLetterform(context: context, rect: rect, size: size)

    #if os(macOS)
    return image
    #else
    return UIGraphicsGetImageFromCurrentImageContext()
    #endif
}

func drawGradientBackground(context: CGContext, rect: CGRect) {
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let gradient = CGGradient(
        colorsSpace: colorSpace,
        colors: [brandPrimary, brandAccent] as CFArray,
        locations: [0.0, 1.0]
    )!

    context.drawLinearGradient(
        gradient,
        start: CGPoint(x: rect.midX, y: rect.minY),
        end: CGPoint(x: rect.midX, y: rect.maxY),
        options: []
    )
}

func drawRLetterform(context: CGContext, rect: CGRect, size: CGFloat) {
    // Use serif font for elegant look
    let fontSize = size * 0.6

    #if os(macOS)
    let font = NSFont(name: "Georgia-Bold", size: fontSize) ?? NSFont.systemFont(ofSize: fontSize, weight: .bold)
    #else
    let font = UIFont(name: "Georgia-Bold", size: fontSize) ?? UIFont.systemFont(ofSize: fontSize, weight: .bold)
    #endif

    let attributes: [NSAttributedString.Key: Any] = [
        .font: font,
        .foregroundColor: CGColor(red: 1, green: 1, blue: 1, alpha: 1.0) // White text
    ]

    let text = "R"
    let attributedString = NSAttributedString(string: text, attributes: attributes)

    #if os(macOS)
    let textRect = attributedString.boundingRect(with: NSSize(width: size, height: size))
    let drawPoint = CGPoint(
        x: rect.midX - textRect.width / 2,
        y: rect.midY - textRect.height / 2
    )
    attributedString.draw(at: drawPoint)
    #else
    let textSize = text.size(withAttributes: attributes)
    let drawPoint = CGPoint(
        x: rect.midX - textSize.width / 2,
        y: rect.midY - textSize.height / 2
    )
    text.draw(at: drawPoint, withAttributes: attributes)
    #endif
}

// MARK: - File Output

func saveIconToFile(image: NSUIImage, size: CGFloat, name: String) {
    let outputDir = FileManager.default.currentDirectoryPath + "/AppIcons"

    do {
        try FileManager.default.createDirectory(atPath: outputDir, withIntermediateDirectories: true)
    } catch {
        print("Error creating output directory: \(error)")
        return
    }

    let filename = "AppIcon-\(name).png"
    let filepath = outputDir + "/" + filename

    #if os(macOS)
    if let tiffData = image.tiffRepresentation,
       let bitmapImage = NSBitmapImageRep(data: tiffData),
       let pngData = bitmapImage.representation(using: .png) {
        do {
            try pngData.write(to: URL(fileURLWithPath: filepath))
            print("✓ Generated \(filename)")
        } catch {
            print("✗ Failed to save \(filename): \(error)")
        }
    }
    #else
    if let pngData = image.pngData() {
        do {
            try pngData.write(to: URL(fileURLWithPath: filepath))
            print("✓ Generated \(filename)")
        } catch {
            print("✗ Failed to save \(filename): \(error)")
        }
    }
    #endif
}

// MARK: - Main

print("Generating Rosier app icons...")
print("Brand Primary: #1A1A2E (Deep Navy)")
print("Brand Accent: #C4A77D (Warm Gold)")
print("")

for (size, name) in iconSizes {
    if let icon = generateAppIcon(size: size) {
        saveIconToFile(image: icon, size: size, name: name)
    }
}

print("")
print("App icon generation complete!")
print("Icons saved to: ./AppIcons/")
print("")
print("Next steps:")
print("1. Create an Asset Catalog in Xcode (Assets.xcassets)")
print("2. Create an App Icon Set within the Asset Catalog")
print("3. Drag all generated PNG files into the appropriate size slots")
print("4. Update Info.plist with: CFBundleIcons: AppIcon")
