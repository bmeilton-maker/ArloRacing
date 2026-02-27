import SpriteKit

class OncomingCarNode: SKSpriteNode {

    /// Speed at which this car moves leftward (toward the player), in pts/sec.
    var oncomingSpeed: CGFloat = 250

    static func create(lane: Int, trackNode: TrackNode, vehicleType: OncomingVehicleType = .sedan) -> OncomingCarNode {
        let colors: [UIColor] = [
            UIColor(red: 0.85, green: 0.2, blue: 0.2, alpha: 1),   // red
            UIColor(red: 0.2, green: 0.4, blue: 0.85, alpha: 1),   // blue
            UIColor(red: 0.1, green: 0.7, blue: 0.65, alpha: 1),   // teal
            UIColor(red: 0.6, green: 0.25, blue: 0.75, alpha: 1),  // purple
            UIColor(red: 0.9, green: 0.8, blue: 0.15, alpha: 1),   // yellow
        ]
        let color = colors[abs(lane) % colors.count]

        let size: CGSize
        let texture: SKTexture

        switch vehicleType {
        case .sedan:
            size = CGSize(width: 55, height: 26)
            let renderSize = CGSize(width: size.width * 2, height: size.height * 2)
            texture = generateSedanTexture(size: renderSize, color: color)
        case .semi:
            size = CGSize(width: 95, height: 28)
            let renderSize = CGSize(width: size.width * 2, height: size.height * 2)
            texture = generateSemiTexture(size: renderSize, color: color)
        case .motorcycle:
            size = CGSize(width: 40, height: 16)
            let renderSize = CGSize(width: size.width * 2, height: size.height * 2)
            texture = generateMotorcycleTexture(size: renderSize, color: color)
        case .dumpTruck:
            size = CGSize(width: 75, height: 30)
            let renderSize = CGSize(width: size.width * 2, height: size.height * 2)
            texture = generateDumpTruckTexture(size: renderSize, color: color)
        }

        let node = OncomingCarNode(texture: texture, size: size)
        node.name = "oncomingCar"
        node.zPosition = ZPositions.car - 1
        node.position = CGPoint(x: 0, y: trackNode.laneYPosition(lane: lane))
        return node
    }

    // MARK: - Sedan (original car)

    private static func generateSedanTexture(size: CGSize, color: UIColor) -> SKTexture {
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { ctx in
            let w = size.width
            let h = size.height

            // Shadow
            UIColor(white: 0, alpha: 0.15).setFill()
            UIBezierPath(roundedRect: CGRect(x: 4, y: h * 0.08, width: w - 8, height: h * 0.84), cornerRadius: w * 0.08).fill()

            // Main body (facing left — front is left side)
            color.setFill()
            let body = UIBezierPath(roundedRect: CGRect(x: 8, y: h * 0.15, width: w - 16, height: h * 0.7), cornerRadius: w * 0.08)
            body.fill()

            // Front taper (left side)
            let front = UIBezierPath()
            front.move(to: CGPoint(x: 8, y: h * 0.22))
            front.addLine(to: CGPoint(x: 3, y: h * 0.35))
            front.addLine(to: CGPoint(x: 3, y: h * 0.65))
            front.addLine(to: CGPoint(x: 8, y: h * 0.78))
            front.close()
            front.fill()

            // Body highlight
            color.withBrightness(1.15).setFill()
            UIBezierPath(roundedRect: CGRect(x: w * 0.25, y: h * 0.38, width: w * 0.45, height: h * 0.07), cornerRadius: 2).fill()

            // Darker lower body
            color.withBrightness(0.75).setFill()
            UIBezierPath(roundedRect: CGRect(x: 12, y: h * 0.6, width: w - 24, height: h * 0.18), cornerRadius: 3).fill()
            UIBezierPath(roundedRect: CGRect(x: 12, y: h * 0.22, width: w - 24, height: h * 0.08), cornerRadius: 3).fill()

            // Windshield (on left side — front)
            UIColor(red: 0.55, green: 0.7, blue: 0.85, alpha: 0.65).setFill()
            UIBezierPath(roundedRect: CGRect(x: w * 0.18, y: h * 0.25, width: w * 0.18, height: h * 0.5), cornerRadius: 3).fill()
            UIColor(white: 1, alpha: 0.25).setFill()
            UIBezierPath(roundedRect: CGRect(x: w * 0.2, y: h * 0.28, width: w * 0.05, height: h * 0.32), cornerRadius: 2).fill()

            // Rear window (right side)
            UIColor(red: 0.45, green: 0.6, blue: 0.75, alpha: 0.5).setFill()
            UIBezierPath(roundedRect: CGRect(x: w * 0.65, y: h * 0.3, width: w * 0.1, height: h * 0.4), cornerRadius: 2).fill()

            // Headlights (left = front)
            UIColor(red: 1, green: 1, blue: 0.8, alpha: 0.95).setFill()
            UIBezierPath(roundedRect: CGRect(x: 3, y: h * 0.22, width: 6, height: 6), cornerRadius: 2).fill()
            UIBezierPath(roundedRect: CGRect(x: 3, y: h * 0.72, width: 6, height: 6), cornerRadius: 2).fill()
            UIColor(red: 1, green: 1, blue: 0.7, alpha: 0.15).setFill()
            UIBezierPath(ovalIn: CGRect(x: -2, y: h * 0.18, width: 14, height: 14)).fill()
            UIBezierPath(ovalIn: CGRect(x: -2, y: h * 0.68, width: 14, height: 14)).fill()

            // Taillights (right = rear)
            UIColor(red: 1, green: 0.15, blue: 0.1, alpha: 0.85).setFill()
            UIBezierPath(roundedRect: CGRect(x: w - 10, y: h * 0.2, width: 5, height: 7), cornerRadius: 2).fill()
            UIBezierPath(roundedRect: CGRect(x: w - 10, y: h * 0.73, width: 5, height: 7), cornerRadius: 2).fill()

            // Wheels
            drawWheel(cx: w * 0.22, cy: 5, r: 7)
            drawWheel(cx: w * 0.22, cy: h - 5, r: 7)
            drawWheel(cx: w * 0.78, cy: 5, r: 7)
            drawWheel(cx: w * 0.78, cy: h - 5, r: 7)
        }
        return SKTexture(image: image)
    }

    // MARK: - Semi Truck (95x28, long cab + trailer)

    private static func generateSemiTexture(size: CGSize, color: UIColor) -> SKTexture {
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { ctx in
            let w = size.width
            let h = size.height

            // Shadow
            UIColor(white: 0, alpha: 0.15).setFill()
            UIBezierPath(roundedRect: CGRect(x: 4, y: h * 0.06, width: w - 8, height: h * 0.88), cornerRadius: 4).fill()

            // Trailer body (rear 60% of vehicle)
            let trailerColor = UIColor(white: 0.75, alpha: 1)
            trailerColor.setFill()
            UIBezierPath(roundedRect: CGRect(x: w * 0.38, y: h * 0.12, width: w * 0.58, height: h * 0.76), cornerRadius: 3).fill()

            // Trailer panel lines
            UIColor(white: 0.65, alpha: 1).setStroke()
            for i in 1...3 {
                let lineX = w * 0.38 + CGFloat(i) * (w * 0.58 / 4)
                let line = UIBezierPath()
                line.move(to: CGPoint(x: lineX, y: h * 0.15))
                line.addLine(to: CGPoint(x: lineX, y: h * 0.85))
                line.lineWidth = 1
                line.stroke()
            }

            // Mud flaps (behind rear wheels)
            UIColor(white: 0.2, alpha: 1).setFill()
            UIBezierPath(rect: CGRect(x: w - 10, y: h * 0.08, width: 3, height: 8)).fill()
            UIBezierPath(rect: CGRect(x: w - 10, y: h * 0.84, width: 3, height: 8)).fill()

            // Cab body (front 35%)
            color.setFill()
            UIBezierPath(roundedRect: CGRect(x: 6, y: h * 0.1, width: w * 0.34, height: h * 0.8), cornerRadius: 5).fill()

            // Cab front taper
            let front = UIBezierPath()
            front.move(to: CGPoint(x: 6, y: h * 0.18))
            front.addLine(to: CGPoint(x: 2, y: h * 0.3))
            front.addLine(to: CGPoint(x: 2, y: h * 0.7))
            front.addLine(to: CGPoint(x: 6, y: h * 0.82))
            front.close()
            color.setFill()
            front.fill()

            // Cab highlight
            color.withBrightness(1.2).setFill()
            UIBezierPath(roundedRect: CGRect(x: w * 0.1, y: h * 0.38, width: w * 0.2, height: h * 0.06), cornerRadius: 2).fill()

            // Windshield
            UIColor(red: 0.55, green: 0.7, blue: 0.85, alpha: 0.7).setFill()
            UIBezierPath(roundedRect: CGRect(x: w * 0.08, y: h * 0.2, width: w * 0.12, height: h * 0.6), cornerRadius: 3).fill()
            UIColor(white: 1, alpha: 0.3).setFill()
            UIBezierPath(roundedRect: CGRect(x: w * 0.09, y: h * 0.22, width: w * 0.03, height: h * 0.35), cornerRadius: 1).fill()

            // Exhaust stacks (top and bottom of cab)
            UIColor(white: 0.4, alpha: 1).setFill()
            UIBezierPath(roundedRect: CGRect(x: w * 0.28, y: h * 0.02, width: 4, height: 10), cornerRadius: 1).fill()
            UIBezierPath(roundedRect: CGRect(x: w * 0.28, y: h * 0.88, width: 4, height: 10), cornerRadius: 1).fill()
            // Stack tips
            UIColor(white: 0.55, alpha: 1).setFill()
            UIBezierPath(roundedRect: CGRect(x: w * 0.28, y: h * 0.02, width: 4, height: 3), cornerRadius: 1).fill()
            UIBezierPath(roundedRect: CGRect(x: w * 0.28, y: h * 0.95, width: 4, height: 3), cornerRadius: 1).fill()

            // Headlights
            UIColor(red: 1, green: 1, blue: 0.8, alpha: 0.95).setFill()
            UIBezierPath(roundedRect: CGRect(x: 2, y: h * 0.22, width: 5, height: 6), cornerRadius: 2).fill()
            UIBezierPath(roundedRect: CGRect(x: 2, y: h * 0.72, width: 5, height: 6), cornerRadius: 2).fill()
            UIColor(red: 1, green: 1, blue: 0.7, alpha: 0.15).setFill()
            UIBezierPath(ovalIn: CGRect(x: -3, y: h * 0.18, width: 14, height: 14)).fill()
            UIBezierPath(ovalIn: CGRect(x: -3, y: h * 0.68, width: 14, height: 14)).fill()

            // Taillights
            UIColor(red: 1, green: 0.15, blue: 0.1, alpha: 0.85).setFill()
            UIBezierPath(roundedRect: CGRect(x: w - 8, y: h * 0.15, width: 4, height: 8), cornerRadius: 2).fill()
            UIBezierPath(roundedRect: CGRect(x: w - 8, y: h * 0.77, width: 4, height: 8), cornerRadius: 2).fill()

            // Wheels — 5 per side (2 cab, 3 trailer)
            let wheelR: CGFloat = 7
            drawWheel(cx: w * 0.12, cy: 4, r: wheelR)
            drawWheel(cx: w * 0.12, cy: h - 4, r: wheelR)
            drawWheel(cx: w * 0.28, cy: 4, r: wheelR)
            drawWheel(cx: w * 0.28, cy: h - 4, r: wheelR)
            drawWheel(cx: w * 0.58, cy: 4, r: wheelR)
            drawWheel(cx: w * 0.58, cy: h - 4, r: wheelR)
            drawWheel(cx: w * 0.72, cy: 4, r: wheelR)
            drawWheel(cx: w * 0.72, cy: h - 4, r: wheelR)
            drawWheel(cx: w * 0.86, cy: 4, r: wheelR)
            drawWheel(cx: w * 0.86, cy: h - 4, r: wheelR)
        }
        return SKTexture(image: image)
    }

    // MARK: - Motorcycle (40x16, narrow, fast)

    private static func generateMotorcycleTexture(size: CGSize, color: UIColor) -> SKTexture {
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { ctx in
            let w = size.width
            let h = size.height

            // Shadow
            UIColor(white: 0, alpha: 0.12).setFill()
            UIBezierPath(ovalIn: CGRect(x: 6, y: h * 0.1, width: w - 12, height: h * 0.8)).fill()

            // Frame / body (thin bar)
            UIColor(white: 0.25, alpha: 1).setFill()
            UIBezierPath(roundedRect: CGRect(x: w * 0.15, y: h * 0.38, width: w * 0.6, height: h * 0.24), cornerRadius: 3).fill()

            // Gas tank / main body
            color.setFill()
            UIBezierPath(roundedRect: CGRect(x: w * 0.25, y: h * 0.28, width: w * 0.35, height: h * 0.44), cornerRadius: 4).fill()

            // Tank highlight
            color.withBrightness(1.25).setFill()
            UIBezierPath(roundedRect: CGRect(x: w * 0.3, y: h * 0.32, width: w * 0.15, height: h * 0.12), cornerRadius: 2).fill()

            // Rider silhouette
            UIColor(white: 0.15, alpha: 0.85).setFill()
            // Torso
            UIBezierPath(roundedRect: CGRect(x: w * 0.35, y: h * 0.2, width: w * 0.2, height: h * 0.6), cornerRadius: 4).fill()
            // Head (helmet)
            UIBezierPath(ovalIn: CGRect(x: w * 0.28, y: h * 0.3, width: w * 0.14, height: h * 0.4)).fill()
            // Helmet visor
            UIColor(red: 0.4, green: 0.55, blue: 0.75, alpha: 0.7).setFill()
            UIBezierPath(roundedRect: CGRect(x: w * 0.26, y: h * 0.38, width: w * 0.06, height: h * 0.2), cornerRadius: 1).fill()

            // Handlebars
            UIColor(white: 0.5, alpha: 1).setFill()
            UIBezierPath(roundedRect: CGRect(x: w * 0.18, y: h * 0.12, width: w * 0.08, height: h * 0.12), cornerRadius: 1).fill()
            UIBezierPath(roundedRect: CGRect(x: w * 0.18, y: h * 0.76, width: w * 0.08, height: h * 0.12), cornerRadius: 1).fill()

            // Exhaust pipe
            UIColor(white: 0.45, alpha: 1).setFill()
            UIBezierPath(roundedRect: CGRect(x: w * 0.55, y: h * 0.7, width: w * 0.3, height: h * 0.1), cornerRadius: 2).fill()
            // Exhaust tip
            UIColor(white: 0.6, alpha: 1).setFill()
            UIBezierPath(roundedRect: CGRect(x: w * 0.82, y: h * 0.68, width: w * 0.06, height: h * 0.14), cornerRadius: 1).fill()

            // Headlight
            UIColor(red: 1, green: 1, blue: 0.8, alpha: 0.95).setFill()
            UIBezierPath(ovalIn: CGRect(x: 2, y: h * 0.35, width: 8, height: h * 0.3)).fill()
            UIColor(red: 1, green: 1, blue: 0.7, alpha: 0.2).setFill()
            UIBezierPath(ovalIn: CGRect(x: -2, y: h * 0.25, width: 14, height: h * 0.5)).fill()

            // Taillight
            UIColor(red: 1, green: 0.15, blue: 0.1, alpha: 0.85).setFill()
            UIBezierPath(roundedRect: CGRect(x: w - 6, y: h * 0.38, width: 4, height: h * 0.24), cornerRadius: 1).fill()

            // Front wheel
            drawWheel(cx: w * 0.1, cy: h * 0.5, r: h * 0.4)
            // Rear wheel
            drawWheel(cx: w * 0.88, cy: h * 0.5, r: h * 0.4)
        }
        return SKTexture(image: image)
    }

    // MARK: - Dump Truck (75x30, wide, slow)

    private static func generateDumpTruckTexture(size: CGSize, color: UIColor) -> SKTexture {
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { ctx in
            let w = size.width
            let h = size.height
            let truckOrange = UIColor(red: 0.9, green: 0.6, blue: 0.1, alpha: 1)

            // Shadow
            UIColor(white: 0, alpha: 0.15).setFill()
            UIBezierPath(roundedRect: CGRect(x: 4, y: h * 0.06, width: w - 8, height: h * 0.88), cornerRadius: 4).fill()

            // Dump bed (rear 58%, angular raised shape)
            truckOrange.setFill()
            let bed = UIBezierPath()
            bed.move(to: CGPoint(x: w * 0.38, y: h * 0.08))
            bed.addLine(to: CGPoint(x: w * 0.42, y: h * 0.02))
            bed.addLine(to: CGPoint(x: w * 0.95, y: h * 0.06))
            bed.addLine(to: CGPoint(x: w * 0.96, y: h * 0.94))
            bed.addLine(to: CGPoint(x: w * 0.42, y: h * 0.98))
            bed.addLine(to: CGPoint(x: w * 0.38, y: h * 0.92))
            bed.close()
            bed.fill()

            // Bed top edge highlight
            truckOrange.withBrightness(1.2).setFill()
            UIBezierPath(roundedRect: CGRect(x: w * 0.42, y: h * 0.04, width: w * 0.52, height: h * 0.06), cornerRadius: 1).fill()
            UIBezierPath(roundedRect: CGRect(x: w * 0.42, y: h * 0.9, width: w * 0.52, height: h * 0.06), cornerRadius: 1).fill()

            // Bed interior shadow
            truckOrange.withBrightness(0.7).setFill()
            UIBezierPath(roundedRect: CGRect(x: w * 0.44, y: h * 0.15, width: w * 0.48, height: h * 0.7), cornerRadius: 2).fill()

            // Caution stripes on rear
            UIColor(white: 0.15, alpha: 1).setFill()
            for i in 0..<3 {
                let stripeY = h * 0.25 + CGFloat(i) * h * 0.2
                UIBezierPath(rect: CGRect(x: w * 0.9, y: stripeY, width: w * 0.04, height: h * 0.12)).fill()
            }

            // Cab body (front 35%)
            color.setFill()
            UIBezierPath(roundedRect: CGRect(x: 5, y: h * 0.12, width: w * 0.35, height: h * 0.76), cornerRadius: 5).fill()

            // Cab front taper
            let front = UIBezierPath()
            front.move(to: CGPoint(x: 5, y: h * 0.2))
            front.addLine(to: CGPoint(x: 2, y: h * 0.32))
            front.addLine(to: CGPoint(x: 2, y: h * 0.68))
            front.addLine(to: CGPoint(x: 5, y: h * 0.8))
            front.close()
            color.setFill()
            front.fill()

            // Cab highlight
            color.withBrightness(1.15).setFill()
            UIBezierPath(roundedRect: CGRect(x: w * 0.08, y: h * 0.38, width: w * 0.22, height: h * 0.06), cornerRadius: 2).fill()

            // Windshield
            UIColor(red: 0.55, green: 0.7, blue: 0.85, alpha: 0.65).setFill()
            UIBezierPath(roundedRect: CGRect(x: w * 0.07, y: h * 0.22, width: w * 0.13, height: h * 0.56), cornerRadius: 3).fill()
            UIColor(white: 1, alpha: 0.25).setFill()
            UIBezierPath(roundedRect: CGRect(x: w * 0.08, y: h * 0.24, width: w * 0.03, height: h * 0.3), cornerRadius: 1).fill()

            // Headlights
            UIColor(red: 1, green: 1, blue: 0.8, alpha: 0.95).setFill()
            UIBezierPath(roundedRect: CGRect(x: 2, y: h * 0.2, width: 5, height: 7), cornerRadius: 2).fill()
            UIBezierPath(roundedRect: CGRect(x: 2, y: h * 0.73, width: 5, height: 7), cornerRadius: 2).fill()
            UIColor(red: 1, green: 1, blue: 0.7, alpha: 0.15).setFill()
            UIBezierPath(ovalIn: CGRect(x: -3, y: h * 0.16, width: 14, height: 14)).fill()
            UIBezierPath(ovalIn: CGRect(x: -3, y: h * 0.69, width: 14, height: 14)).fill()

            // Taillights
            UIColor(red: 1, green: 0.15, blue: 0.1, alpha: 0.85).setFill()
            UIBezierPath(roundedRect: CGRect(x: w - 8, y: h * 0.14, width: 4, height: 8), cornerRadius: 2).fill()
            UIBezierPath(roundedRect: CGRect(x: w - 8, y: h * 0.78, width: 4, height: 8), cornerRadius: 2).fill()

            // Wheels — 3 per side (1 cab, 2 trailer)
            let wheelR: CGFloat = 8
            drawWheel(cx: w * 0.18, cy: 4, r: wheelR)
            drawWheel(cx: w * 0.18, cy: h - 4, r: wheelR)
            drawWheel(cx: w * 0.65, cy: 4, r: wheelR)
            drawWheel(cx: w * 0.65, cy: h - 4, r: wheelR)
            drawWheel(cx: w * 0.82, cy: 4, r: wheelR)
            drawWheel(cx: w * 0.82, cy: h - 4, r: wheelR)
        }
        return SKTexture(image: image)
    }

    // MARK: - Shared

    private static func drawWheel(cx: CGFloat, cy: CGFloat, r: CGFloat) {
        UIColor(white: 0.15, alpha: 1).setFill()
        UIBezierPath(ovalIn: CGRect(x: cx - r, y: cy - r, width: r * 2, height: r * 2)).fill()
        UIColor(white: 0.55, alpha: 1).setFill()
        UIBezierPath(ovalIn: CGRect(x: cx - r * 0.55, y: cy - r * 0.55, width: r * 1.1, height: r * 1.1)).fill()
        UIColor(white: 0.7, alpha: 1).setFill()
        UIBezierPath(ovalIn: CGRect(x: cx - r * 0.2, y: cy - r * 0.2, width: r * 0.4, height: r * 0.4)).fill()
    }
}

private extension UIColor {
    func withBrightness(_ factor: CGFloat) -> UIColor {
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        getHue(&h, saturation: &s, brightness: &b, alpha: &a)
        return UIColor(hue: h, saturation: s, brightness: min(b * factor, 1.0), alpha: a)
    }
}
