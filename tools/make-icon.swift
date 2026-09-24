import AppKit
import Foundation

// Иконка источника и приложения. Координаты — те же, что в векторной метке
// приложения (холст 108×108, ось Y вниз): две метки, нарисованные в разных
// местах по разным числам, рано или поздно разойдутся.
//
//     swift tools/make-icon.swift

let size: CGFloat = 512
let accent = NSColor(red: 0.04, green: 0.52, blue: 1.0, alpha: 1)

// Метка занимает по вектору x 34…74 и y 12…76 — центр (54, 44).
let scale: CGFloat = 5.0
func p(_ vx: CGFloat, _ vy: CGFloat) -> CGPoint {
    CGPoint(x: size / 2 + (vx - 54) * scale, y: size / 2 - (vy - 44) * scale)
}
func box(_ vx: CGFloat, _ vy: CGFloat, _ w: CGFloat, _ h: CGFloat) -> CGRect {
    let top = p(vx, vy)
    return CGRect(x: top.x, y: top.y - h * scale, width: w * scale, height: h * scale)
}

let rep = NSBitmapImageRep(
    bitmapDataPlanes: nil, pixelsWide: Int(size), pixelsHigh: Int(size),
    bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
    colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!

NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
let ctx = NSGraphicsContext.current!.cgContext

ctx.setFillColor(NSColor.black.cgColor)
ctx.fill(CGRect(x: 0, y: 0, width: size, height: size))

let ring = p(54, 32)
ctx.setStrokeColor(accent.cgColor)
ctx.setLineWidth(5 * scale)
ctx.strokeEllipse(in: CGRect(x: ring.x - 20 * scale, y: ring.y - 20 * scale,
                             width: 40 * scale, height: 40 * scale))

ctx.setFillColor(accent.cgColor)
ctx.fillEllipse(in: CGRect(x: ring.x - 7 * scale, y: ring.y - 7 * scale,
                           width: 14 * scale, height: 14 * scale))

ctx.setFillColor(accent.withAlphaComponent(0.55).cgColor)
ctx.fill(box(51, 66, 6, 8))
ctx.fill(box(51, 76, 6, 6))

NSGraphicsContext.restoreGraphicsState()

let out = URL(fileURLWithPath: "assets/icon.png")
try rep.representation(using: .png, properties: [:])!.write(to: out)
print("готово: \(out.path)")
