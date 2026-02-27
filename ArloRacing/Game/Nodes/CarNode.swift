import SpriteKit
import SwiftUI

class CarNode: SKSpriteNode {

    static func create(vehicleId: String, color: Color) -> CarNode {
        // 10% bigger than original sizes
        let size: CGSize
        switch vehicleId {
        case "motorcycle":
            size = CGSize(width: 55, height: 24)
        case "monster":
            size = CGSize(width: 66, height: 39)
        case "pickup":
            size = CGSize(width: 61, height: 33)
        default: // sports
            size = CGSize(width: 61, height: 29)
        }

        // Render at 2x for retina sharpness
        let renderSize = CGSize(width: size.width * 2, height: size.height * 2)
        let texture = CarNode.generateTexture(vehicleId: vehicleId, size: renderSize, color: UIColor(color))
        let node = CarNode(texture: texture, size: size)
        node.name = "car"
        node.zPosition = ZPositions.car
        return node
    }

    private static func generateTexture(vehicleId: String, size: CGSize, color: UIColor) -> SKTexture {
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { ctx in
            let w = size.width
            let h = size.height
            let c = ctx.cgContext

            switch vehicleId {
            case "motorcycle":
                drawMotorcycle(c: c, w: w, h: h, color: color)
            case "monster":
                drawMonsterTruck(c: c, w: w, h: h, color: color)
            case "pickup":
                drawPickupTruck(c: c, w: w, h: h, color: color)
            default:
                drawSportsCar(c: c, w: w, h: h, color: color)
            }
        }
        return SKTexture(image: image)
    }

    // MARK: - Sports Car

    private static func drawSportsCar(c: CGContext, w: CGFloat, h: CGFloat, color: UIColor) {
        // Shadow
        UIColor(white: 0, alpha: 0.15).setFill()
        UIBezierPath(roundedRect: CGRect(x: 6, y: h * 0.08, width: w - 10, height: h * 0.84), cornerRadius: w * 0.1).fill()

        // Main body — sleek shape
        color.setFill()
        let body = UIBezierPath(roundedRect: CGRect(x: 8, y: h * 0.15, width: w - 16, height: h * 0.7), cornerRadius: w * 0.08)
        body.fill()

        // Hood taper (front of car = right side, narrower)
        let hood = UIBezierPath()
        hood.move(to: CGPoint(x: w - 8, y: h * 0.22))
        hood.addLine(to: CGPoint(x: w - 2, y: h * 0.35))
        hood.addLine(to: CGPoint(x: w - 2, y: h * 0.65))
        hood.addLine(to: CGPoint(x: w - 8, y: h * 0.78))
        hood.close()
        hood.fill()

        // Body highlight stripe
        color.withBrightness(1.2).setFill()
        UIBezierPath(roundedRect: CGRect(x: w * 0.15, y: h * 0.38, width: w * 0.55, height: h * 0.08), cornerRadius: 2).fill()

        // Darker lower body
        color.withBrightness(0.75).setFill()
        UIBezierPath(roundedRect: CGRect(x: 10, y: h * 0.6, width: w - 22, height: h * 0.2), cornerRadius: 3).fill()
        UIBezierPath(roundedRect: CGRect(x: 10, y: h * 0.2, width: w - 22, height: h * 0.1), cornerRadius: 3).fill()

        // Windshield
        UIColor(red: 0.55, green: 0.7, blue: 0.85, alpha: 0.7).setFill()
        let windshield = UIBezierPath(roundedRect: CGRect(x: w * 0.55, y: h * 0.25, width: w * 0.2, height: h * 0.5), cornerRadius: 4)
        windshield.fill()
        // Windshield shine
        UIColor(white: 1, alpha: 0.3).setFill()
        UIBezierPath(roundedRect: CGRect(x: w * 0.58, y: h * 0.28, width: w * 0.06, height: h * 0.35), cornerRadius: 2).fill()

        // Rear window
        UIColor(red: 0.45, green: 0.6, blue: 0.75, alpha: 0.5).setFill()
        UIBezierPath(roundedRect: CGRect(x: w * 0.22, y: h * 0.3, width: w * 0.12, height: h * 0.4), cornerRadius: 3).fill()

        // Headlights (right side = front)
        UIColor(red: 1, green: 1, blue: 0.8, alpha: 0.9).setFill()
        UIBezierPath(roundedRect: CGRect(x: w - 12, y: h * 0.22, width: 6, height: 6), cornerRadius: 2).fill()
        UIBezierPath(roundedRect: CGRect(x: w - 12, y: h * 0.72, width: 6, height: 6), cornerRadius: 2).fill()

        // Taillights (left side = rear)
        UIColor(red: 1, green: 0.15, blue: 0.1, alpha: 0.9).setFill()
        UIBezierPath(roundedRect: CGRect(x: 6, y: h * 0.18, width: 6, height: 8), cornerRadius: 2).fill()
        UIBezierPath(roundedRect: CGRect(x: 6, y: h * 0.74, width: 6, height: 8), cornerRadius: 2).fill()

        // Wheels with rims
        drawWheel(c: c, cx: w * 0.22, cy: 4, r: 7)
        drawWheel(c: c, cx: w * 0.22, cy: h - 4, r: 7)
        drawWheel(c: c, cx: w * 0.78, cy: 4, r: 7)
        drawWheel(c: c, cx: w * 0.78, cy: h - 4, r: 7)

        // Exhaust pipes (rear left)
        UIColor(white: 0.35, alpha: 1).setFill()
        UIBezierPath(ovalIn: CGRect(x: 2, y: h * 0.35, width: 5, height: 4)).fill()
        UIBezierPath(ovalIn: CGRect(x: 2, y: h * 0.58, width: 5, height: 4)).fill()
    }

    // MARK: - Pickup Truck

    private static func drawPickupTruck(c: CGContext, w: CGFloat, h: CGFloat, color: UIColor) {
        // Shadow
        UIColor(white: 0, alpha: 0.15).setFill()
        UIBezierPath(roundedRect: CGRect(x: 4, y: h * 0.08, width: w - 6, height: h * 0.84), cornerRadius: 6).fill()

        // Truck bed (rear = left side)
        color.withBrightness(0.8).setFill()
        let bed = UIBezierPath(roundedRect: CGRect(x: 6, y: h * 0.18, width: w * 0.42, height: h * 0.64), cornerRadius: 4)
        bed.fill()
        // Bed interior
        UIColor(white: 0.25, alpha: 0.4).setFill()
        UIBezierPath(roundedRect: CGRect(x: 10, y: h * 0.24, width: w * 0.34, height: h * 0.52), cornerRadius: 2).fill()
        // Bed rail highlights
        color.withBrightness(0.9).setFill()
        UIBezierPath(roundedRect: CGRect(x: 6, y: h * 0.18, width: w * 0.42, height: h * 0.05), cornerRadius: 2).fill()
        UIBezierPath(roundedRect: CGRect(x: 6, y: h * 0.77, width: w * 0.42, height: h * 0.05), cornerRadius: 2).fill()

        // Cabin
        color.setFill()
        let cabin = UIBezierPath(roundedRect: CGRect(x: w * 0.45, y: h * 0.12, width: w * 0.48, height: h * 0.76), cornerRadius: 6)
        cabin.fill()

        // Cabin highlight
        color.withBrightness(1.15).setFill()
        UIBezierPath(roundedRect: CGRect(x: w * 0.48, y: h * 0.35, width: w * 0.38, height: h * 0.06), cornerRadius: 2).fill()

        // Hood bump
        color.withBrightness(0.95).setFill()
        let hoodBump = UIBezierPath(roundedRect: CGRect(x: w * 0.85, y: h * 0.25, width: w * 0.12, height: h * 0.5), cornerRadius: 4)
        hoodBump.fill()

        // Windshield
        UIColor(red: 0.55, green: 0.7, blue: 0.85, alpha: 0.65).setFill()
        UIBezierPath(roundedRect: CGRect(x: w * 0.72, y: h * 0.22, width: w * 0.14, height: h * 0.56), cornerRadius: 3).fill()
        UIColor(white: 1, alpha: 0.25).setFill()
        UIBezierPath(roundedRect: CGRect(x: w * 0.74, y: h * 0.25, width: w * 0.04, height: h * 0.38), cornerRadius: 2).fill()

        // Rear window
        UIColor(red: 0.45, green: 0.6, blue: 0.75, alpha: 0.5).setFill()
        UIBezierPath(roundedRect: CGRect(x: w * 0.48, y: h * 0.26, width: w * 0.1, height: h * 0.48), cornerRadius: 2).fill()

        // Headlights
        UIColor(red: 1, green: 1, blue: 0.8, alpha: 0.9).setFill()
        UIBezierPath(roundedRect: CGRect(x: w - 8, y: h * 0.2, width: 5, height: 7), cornerRadius: 2).fill()
        UIBezierPath(roundedRect: CGRect(x: w - 8, y: h * 0.73, width: 5, height: 7), cornerRadius: 2).fill()

        // Taillights
        UIColor(red: 1, green: 0.15, blue: 0.1, alpha: 0.85).setFill()
        UIBezierPath(roundedRect: CGRect(x: 4, y: h * 0.2, width: 5, height: 7), cornerRadius: 2).fill()
        UIBezierPath(roundedRect: CGRect(x: 4, y: h * 0.73, width: 5, height: 7), cornerRadius: 2).fill()

        // Wheels
        drawWheel(c: c, cx: w * 0.22, cy: 3, r: 8)
        drawWheel(c: c, cx: w * 0.22, cy: h - 3, r: 8)
        drawWheel(c: c, cx: w * 0.78, cy: 3, r: 8)
        drawWheel(c: c, cx: w * 0.78, cy: h - 3, r: 8)

        // Bull bar (front)
        UIColor(white: 0.6, alpha: 0.8).setFill()
        UIBezierPath(roundedRect: CGRect(x: w - 4, y: h * 0.15, width: 3, height: h * 0.7), cornerRadius: 1).fill()
    }

    // MARK: - Monster Truck

    private static func drawMonsterTruck(c: CGContext, w: CGFloat, h: CGFloat, color: UIColor) {
        // Shadow
        UIColor(white: 0, alpha: 0.15).setFill()
        UIBezierPath(roundedRect: CGRect(x: 10, y: h * 0.2, width: w - 20, height: h * 0.65), cornerRadius: 6).fill()

        // Huge wheels (draw first, behind body)
        drawMonsterWheel(c: c, cx: w * 0.2, cy: 4, r: 12)
        drawMonsterWheel(c: c, cx: w * 0.2, cy: h - 4, r: 12)
        drawMonsterWheel(c: c, cx: w * 0.8, cy: 4, r: 12)
        drawMonsterWheel(c: c, cx: w * 0.8, cy: h - 4, r: 12)

        // Suspension struts
        UIColor(white: 0.35, alpha: 1).setFill()
        UIBezierPath(roundedRect: CGRect(x: w * 0.18, y: 2, width: 4, height: h * 0.25), cornerRadius: 1).fill()
        UIBezierPath(roundedRect: CGRect(x: w * 0.18, y: h * 0.75, width: 4, height: h * 0.23), cornerRadius: 1).fill()
        UIBezierPath(roundedRect: CGRect(x: w * 0.78, y: 2, width: 4, height: h * 0.25), cornerRadius: 1).fill()
        UIBezierPath(roundedRect: CGRect(x: w * 0.78, y: h * 0.75, width: 4, height: h * 0.23), cornerRadius: 1).fill()

        // Main body — raised high
        color.setFill()
        let body = UIBezierPath(roundedRect: CGRect(x: w * 0.1, y: h * 0.25, width: w * 0.8, height: h * 0.5), cornerRadius: 6)
        body.fill()

        // Body highlight
        color.withBrightness(1.2).setFill()
        UIBezierPath(roundedRect: CGRect(x: w * 0.15, y: h * 0.38, width: w * 0.6, height: h * 0.06), cornerRadius: 2).fill()

        // Roll cage outline
        color.withBrightness(0.7).setStroke()
        let cage = UIBezierPath(roundedRect: CGRect(x: w * 0.12, y: h * 0.28, width: w * 0.76, height: h * 0.44), cornerRadius: 5)
        cage.lineWidth = 1.5
        cage.stroke()

        // Windshield
        UIColor(red: 0.55, green: 0.7, blue: 0.85, alpha: 0.6).setFill()
        UIBezierPath(roundedRect: CGRect(x: w * 0.6, y: h * 0.32, width: w * 0.16, height: h * 0.36), cornerRadius: 3).fill()
        UIColor(white: 1, alpha: 0.2).setFill()
        UIBezierPath(roundedRect: CGRect(x: w * 0.62, y: h * 0.34, width: w * 0.05, height: h * 0.25), cornerRadius: 2).fill()

        // Racing number circle
        UIColor.white.setFill()
        UIBezierPath(ovalIn: CGRect(x: w * 0.38, y: h * 0.38, width: h * 0.24, height: h * 0.24)).fill()

        // Headlights
        UIColor(red: 1, green: 1, blue: 0.8, alpha: 0.9).setFill()
        UIBezierPath(ovalIn: CGRect(x: w * 0.85, y: h * 0.3, width: 6, height: 6)).fill()
        UIBezierPath(ovalIn: CGRect(x: w * 0.85, y: h * 0.62, width: 6, height: 6)).fill()

        // Exhaust stack (rear top)
        UIColor(white: 0.3, alpha: 1).setFill()
        UIBezierPath(roundedRect: CGRect(x: w * 0.08, y: h * 0.2, width: 4, height: h * 0.12), cornerRadius: 1).fill()
    }

    // MARK: - Motorcycle

    private static func drawMotorcycle(c: CGContext, w: CGFloat, h: CGFloat, color: UIColor) {
        // Wheels first (behind body)
        drawWheel(c: c, cx: w * 0.15, cy: h * 0.5, r: 8)
        drawWheel(c: c, cx: w * 0.85, cy: h * 0.5, r: 8)

        // Forks
        UIColor(white: 0.55, alpha: 1).setFill()
        UIBezierPath(roundedRect: CGRect(x: w * 0.78, y: h * 0.28, width: 3, height: h * 0.44), cornerRadius: 1).fill()
        UIBezierPath(roundedRect: CGRect(x: w * 0.12, y: h * 0.33, width: 3, height: h * 0.34), cornerRadius: 1).fill()

        // Chain/frame line
        UIColor(white: 0.3, alpha: 0.5).setStroke()
        let frame = UIBezierPath()
        frame.move(to: CGPoint(x: w * 0.2, y: h * 0.5))
        frame.addLine(to: CGPoint(x: w * 0.5, y: h * 0.35))
        frame.addLine(to: CGPoint(x: w * 0.8, y: h * 0.5))
        frame.lineWidth = 2
        frame.stroke()

        // Engine block
        UIColor(white: 0.3, alpha: 1).setFill()
        UIBezierPath(roundedRect: CGRect(x: w * 0.35, y: h * 0.4, width: w * 0.2, height: h * 0.22), cornerRadius: 2).fill()

        // Fuel tank (main body color)
        color.setFill()
        let tank = UIBezierPath(roundedRect: CGRect(x: w * 0.32, y: h * 0.25, width: w * 0.3, height: h * 0.2), cornerRadius: 4)
        tank.fill()
        // Tank highlight
        color.withBrightness(1.3).setFill()
        UIBezierPath(roundedRect: CGRect(x: w * 0.35, y: h * 0.28, width: w * 0.15, height: h * 0.06), cornerRadius: 2).fill()

        // Seat
        UIColor(white: 0.2, alpha: 1).setFill()
        let seat = UIBezierPath()
        seat.move(to: CGPoint(x: w * 0.25, y: h * 0.3))
        seat.addQuadCurve(to: CGPoint(x: w * 0.5, y: h * 0.25), controlPoint: CGPoint(x: w * 0.38, y: h * 0.22))
        seat.addLine(to: CGPoint(x: w * 0.5, y: h * 0.32))
        seat.addLine(to: CGPoint(x: w * 0.25, y: h * 0.38))
        seat.close()
        seat.fill()
        // Mirrored seat for bottom half (top-down view symmetry)
        UIColor(white: 0.2, alpha: 1).setFill()
        let seat2 = UIBezierPath()
        seat2.move(to: CGPoint(x: w * 0.25, y: h * 0.7))
        seat2.addQuadCurve(to: CGPoint(x: w * 0.5, y: h * 0.75), controlPoint: CGPoint(x: w * 0.38, y: h * 0.78))
        seat2.addLine(to: CGPoint(x: w * 0.5, y: h * 0.68))
        seat2.addLine(to: CGPoint(x: w * 0.25, y: h * 0.62))
        seat2.close()
        seat2.fill()

        // Handlebars
        UIColor(white: 0.55, alpha: 1).setFill()
        UIBezierPath(roundedRect: CGRect(x: w * 0.7, y: h * 0.15, width: 3, height: h * 0.7), cornerRadius: 1).fill()

        // Headlight
        UIColor(red: 1, green: 1, blue: 0.8, alpha: 0.9).setFill()
        UIBezierPath(ovalIn: CGRect(x: w * 0.87, y: h * 0.4, width: 6, height: 6)).fill()

        // Taillight
        UIColor.red.setFill()
        UIBezierPath(ovalIn: CGRect(x: w * 0.05, y: h * 0.43, width: 4, height: 4)).fill()

        // Exhaust pipe
        UIColor(white: 0.45, alpha: 1).setFill()
        let exhaust = UIBezierPath(roundedRect: CGRect(x: w * 0.2, y: h * 0.62, width: w * 0.22, height: 3), cornerRadius: 1)
        exhaust.fill()
    }

    // MARK: - Wheel Helpers

    private static func drawWheel(c: CGContext, cx: CGFloat, cy: CGFloat, r: CGFloat) {
        // Tire
        UIColor(white: 0.15, alpha: 1).setFill()
        UIBezierPath(ovalIn: CGRect(x: cx - r, y: cy - r, width: r * 2, height: r * 2)).fill()
        // Rim
        UIColor(white: 0.55, alpha: 1).setFill()
        UIBezierPath(ovalIn: CGRect(x: cx - r * 0.55, y: cy - r * 0.55, width: r * 1.1, height: r * 1.1)).fill()
        // Hub
        UIColor(white: 0.7, alpha: 1).setFill()
        UIBezierPath(ovalIn: CGRect(x: cx - r * 0.2, y: cy - r * 0.2, width: r * 0.4, height: r * 0.4)).fill()
    }

    private static func drawMonsterWheel(c: CGContext, cx: CGFloat, cy: CGFloat, r: CGFloat) {
        // Big knobby tire
        UIColor(white: 0.12, alpha: 1).setFill()
        UIBezierPath(ovalIn: CGRect(x: cx - r, y: cy - r, width: r * 2, height: r * 2)).fill()
        // Tread pattern — simple notches
        UIColor(white: 0.22, alpha: 1).setFill()
        for i in 0..<6 {
            let angle = CGFloat(i) * (.pi / 3)
            let nx = cx + cos(angle) * r * 0.7
            let ny = cy + sin(angle) * r * 0.7
            UIBezierPath(ovalIn: CGRect(x: nx - 2, y: ny - 2, width: 4, height: 4)).fill()
        }
        // Rim
        UIColor(red: 0.85, green: 0.75, blue: 0.2, alpha: 1).setFill()
        UIBezierPath(ovalIn: CGRect(x: cx - r * 0.45, y: cy - r * 0.45, width: r * 0.9, height: r * 0.9)).fill()
        // Hub
        UIColor(white: 0.6, alpha: 1).setFill()
        UIBezierPath(ovalIn: CGRect(x: cx - r * 0.15, y: cy - r * 0.15, width: r * 0.3, height: r * 0.3)).fill()
    }
}

// MARK: - UIColor brightness helper

private extension UIColor {
    func withBrightness(_ factor: CGFloat) -> UIColor {
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        getHue(&h, saturation: &s, brightness: &b, alpha: &a)
        return UIColor(hue: h, saturation: s, brightness: min(b * factor, 1.0), alpha: a)
    }
}
