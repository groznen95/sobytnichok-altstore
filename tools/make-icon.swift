import AppKit
import Foundation

// Иконка источника и приложения.
//
// Геометрия метки — та же, что в векторной иконке приложения (холст 108×108,
// ось Y вниз): две метки, нарисованные в разных местах по разным числам, рано
// или поздно разойдутся. Отличается только отделка: на маленьком квадрате
// плоская заливка выглядит распечаткой, поэтому здесь свечение и градиенты.
//
//     swift tools/make-icon.swift                 # иконка источника
//     swift tools/make-icon.swift путь/AppIcon.png # она же для приложения

let size: CGFloat = 1024
let outputPath = CommandLine.arguments.dropFirst().first ?? "assets/icon.png"
let accent = NSColor(red: 0.04, green: 0.52, blue: 1.0, alpha: 1)
let accentLight = NSColor(red: 0.35, green: 0.75, blue: 1.0, alpha: 1)

// Метка занимает по вектору x 34…74 и y 12…76 — центр (54, 44).
let scale: CGFloat = size / 108 * 1.02
func p(_ vx: CGFloat, _ vy: CGFloat) -> CGPoint {
    CGPoint(x: size / 2 + (vx - 54) * scale, y: size / 2 - (vy - 44) * scale)
}

let rep = NSBitmapImageRep(
    bitmapDataPlanes: nil, pixelsWide: Int(size), pixelsHigh: Int(size),
    bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
    colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!

NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
let ctx = NSGraphicsContext.current!.cgContext
let space = CGColorSpaceCreateDeviceRGB()
let full = CGRect(x: 0, y: 0, width: size, height: size)

// MARK: Фон

// Не чёрный, а очень тёмный синий сверху: на чёрном квадрате среди чёрных же
// иконок метка теряется, а холодный верх отделяет её от соседей по экрану.
ctx.setFillColor(NSColor.black.cgColor)
ctx.fill(full)
let bg = CGGradient(colorsSpace: space, colors: [
    NSColor(red: 0.05, green: 0.11, blue: 0.20, alpha: 1).cgColor,
    NSColor(red: 0.01, green: 0.02, blue: 0.04, alpha: 1).cgColor,
] as CFArray, locations: [0, 1])!
ctx.drawLinearGradient(bg, start: CGPoint(x: 0, y: size), end: CGPoint(x: 0, y: 0), options: [])

let ring = p(54, 32)

// Свечение за кольцом — единственное украшение. Оно же не даёт метке
// выглядеть наклеенной поверх фона.
let glow = CGGradient(colorsSpace: space, colors: [
    accent.withAlphaComponent(0.55).cgColor,
    accent.withAlphaComponent(0.0).cgColor,
] as CFArray, locations: [0, 1])!
ctx.drawRadialGradient(glow, startCenter: ring, startRadius: 0,
                       endCenter: ring, endRadius: 30 * scale, options: [])

// MARK: Метка

let ringRect = CGRect(x: ring.x - 20 * scale, y: ring.y - 20 * scale,
                      width: 40 * scale, height: 40 * scale)

// Градиент по кольцу: сверху светлее, снизу — основной акцент. Заливается
// через обтравку по контуру кольца, потому что CGContext не умеет
// градиентную обводку.
ctx.saveGState()
let stroke = CGPath(ellipseIn: ringRect, transform: nil)
    .copy(strokingWithWidth: 5 * scale, lineCap: .round, lineJoin: .round, miterLimit: 10)
ctx.addPath(stroke)
ctx.clip()
let ringGradient = CGGradient(colorsSpace: space, colors: [
    accentLight.cgColor, accent.cgColor,
] as CFArray, locations: [0, 1])!
ctx.drawLinearGradient(ringGradient,
                       start: CGPoint(x: ringRect.minX, y: ringRect.maxY),
                       end: CGPoint(x: ringRect.maxX, y: ringRect.minY), options: [])
ctx.restoreGState()

// Точка в центре — состояние события. У неё своё свечение: она и есть то,
// ради чего иконка существует.
let dotRect = CGRect(x: ring.x - 7 * scale, y: ring.y - 7 * scale,
                     width: 14 * scale, height: 14 * scale)
ctx.saveGState()
ctx.setShadow(offset: .zero, blur: 6 * scale, color: accent.withAlphaComponent(0.9).cgColor)
ctx.setFillColor(accentLight.cgColor)
ctx.fillEllipse(in: dotRect)
ctx.restoreGState()

// Ножка: два штриха вниз, затухающие. Это «что дальше» — продолжение,
// которое ещё не наступило, поэтому оно бледнее самой точки.
func bar(_ vy: CGFloat, _ h: CGFloat, alpha: CGFloat) {
    let top = p(51, vy)
    let r = CGRect(x: top.x, y: top.y - h * scale, width: 6 * scale, height: h * scale)
    ctx.setFillColor(accent.withAlphaComponent(alpha).cgColor)
    ctx.addPath(CGPath(roundedRect: r, cornerWidth: 3 * scale, cornerHeight: 3 * scale,
                       transform: nil))
    ctx.fillPath()
}
bar(66, 8, alpha: 0.85)
bar(77, 6, alpha: 0.45)

NSGraphicsContext.restoreGraphicsState()

let out = URL(fileURLWithPath: outputPath)
try rep.representation(using: .png, properties: [:])!.write(to: out)
print("готово: \(out.path) — \(Int(size))×\(Int(size))")
