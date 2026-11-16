import SpriteKit

class ObstacleNode: SKSpriteNode {
    let obstacleType: ObstacleType

    // Textures are identical per type — render each once, not per node
    // (a track spawns dozens of these at scene setup).
    private static var textureCache: [ObstacleType: SKTexture] = [:]

    private static func texture(for type: ObstacleType, renderSize: CGSize) -> SKTexture {
        if let cached = textureCache[type] { return cached }
        let texture: SKTexture
        switch type {
        case .cone:
            texture = generateConeTexture(size: renderSize)
        case .banana:
            texture = generateBananaTexture(size: renderSize)
        }
        textureCache[type] = texture
        return texture
    }

    init(type: ObstacleType) {
        self.obstacleType = type
        let size: CGSize
        switch type {
        case .cone:
            // 10% bigger
            size = CGSize(width: 26, height: 31)
        case .banana:
            size = CGSize(width: 29, height: 15)
        }
        let texture = ObstacleNode.texture(for: type, renderSize: CGSize(width: size.width * 2, height: size.height * 2))

        super.init(texture: texture, color: .clear, size: size)
        self.name = "obstacle"
        self.zPosition = ZPositions.obstacles
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Cone

    private static func generateConeTexture(size: CGSize) -> SKTexture {
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { _ in
            let w = size.width
            let h = size.height

            // UIKit y=0 is top → SpriteKit flips
            // Draw tip at y=0 (UIKit top) so it appears tip-up in SpriteKit

            // Shadow ellipse at base
            UIColor(white: 0, alpha: 0.15).setFill()
            UIBezierPath(ovalIn: CGRect(x: w * 0.1, y: h * 0.82, width: w * 0.8, height: h * 0.16)).fill()

            // Base plate
            UIColor(white: 0.2, alpha: 1).setFill()
            UIBezierPath(roundedRect: CGRect(x: w * 0.05, y: h * 0.85, width: w * 0.9, height: h * 0.12), cornerRadius: 3).fill()

            // Cone body — left half (darker orange for 3D effect)
            UIColor(red: 0.9, green: 0.45, blue: 0.05, alpha: 1).setFill()
            let leftHalf = UIBezierPath()
            leftHalf.move(to: CGPoint(x: w * 0.5, y: h * 0.02))
            leftHalf.addLine(to: CGPoint(x: w * 0.12, y: h * 0.85))
            leftHalf.addLine(to: CGPoint(x: w * 0.5, y: h * 0.85))
            leftHalf.close()
            leftHalf.fill()

            // Cone body — right half (brighter orange highlight)
            UIColor(red: 1.0, green: 0.55, blue: 0.1, alpha: 1).setFill()
            let rightHalf = UIBezierPath()
            rightHalf.move(to: CGPoint(x: w * 0.5, y: h * 0.02))
            rightHalf.addLine(to: CGPoint(x: w * 0.88, y: h * 0.85))
            rightHalf.addLine(to: CGPoint(x: w * 0.5, y: h * 0.85))
            rightHalf.close()
            rightHalf.fill()

            // White reflective stripes (two bands)
            UIColor.white.setFill()
            // Upper stripe
            let s1y = h * 0.3
            let s1Left = w * 0.5 - (w * 0.38 * (s1y / (h * 0.85)))
            let s1Right = w * 0.5 + (w * 0.38 * (s1y / (h * 0.85)))
            let s1Bottom = s1y + h * 0.08
            let s1LeftB = w * 0.5 - (w * 0.38 * (s1Bottom / (h * 0.85)))
            let s1RightB = w * 0.5 + (w * 0.38 * (s1Bottom / (h * 0.85)))
            let stripe1 = UIBezierPath()
            stripe1.move(to: CGPoint(x: s1Left, y: s1y))
            stripe1.addLine(to: CGPoint(x: s1Right, y: s1y))
            stripe1.addLine(to: CGPoint(x: s1RightB, y: s1Bottom))
            stripe1.addLine(to: CGPoint(x: s1LeftB, y: s1Bottom))
            stripe1.close()
            stripe1.fill()

            // Lower stripe
            let s2y = h * 0.55
            let s2Left = w * 0.5 - (w * 0.38 * (s2y / (h * 0.85)))
            let s2Right = w * 0.5 + (w * 0.38 * (s2y / (h * 0.85)))
            let s2Bottom = s2y + h * 0.08
            let s2LeftB = w * 0.5 - (w * 0.38 * (s2Bottom / (h * 0.85)))
            let s2RightB = w * 0.5 + (w * 0.38 * (s2Bottom / (h * 0.85)))
            let stripe2 = UIBezierPath()
            stripe2.move(to: CGPoint(x: s2Left, y: s2y))
            stripe2.addLine(to: CGPoint(x: s2Right, y: s2y))
            stripe2.addLine(to: CGPoint(x: s2RightB, y: s2Bottom))
            stripe2.addLine(to: CGPoint(x: s2LeftB, y: s2Bottom))
            stripe2.close()
            stripe2.fill()

            // Highlight edge (shine on right side)
            UIColor(white: 1, alpha: 0.2).setFill()
            let shine = UIBezierPath()
            shine.move(to: CGPoint(x: w * 0.52, y: h * 0.05))
            shine.addLine(to: CGPoint(x: w * 0.58, y: h * 0.05))
            shine.addLine(to: CGPoint(x: w * 0.72, y: h * 0.82))
            shine.addLine(to: CGPoint(x: w * 0.62, y: h * 0.82))
            shine.close()
            shine.fill()

            // Tip cap
            UIColor(red: 1.0, green: 0.6, blue: 0.15, alpha: 1).setFill()
            UIBezierPath(ovalIn: CGRect(x: w * 0.38, y: 0, width: w * 0.24, height: h * 0.1)).fill()
        }
        return SKTexture(image: image)
    }

    // MARK: - Banana

    private static func generateBananaTexture(size: CGSize) -> SKTexture {
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { _ in
            let w = size.width
            let h = size.height

            // Shadow
            UIColor(white: 0, alpha: 0.1).setFill()
            UIBezierPath(ovalIn: CGRect(x: w * 0.08, y: h * 0.55, width: w * 0.84, height: h * 0.35)).fill()

            // Banana body — main yellow curved shape
            UIColor(red: 1.0, green: 0.88, blue: 0.2, alpha: 1).setFill()
            let banana = UIBezierPath()
            banana.move(to: CGPoint(x: w * 0.08, y: h * 0.55))
            banana.addQuadCurve(to: CGPoint(x: w * 0.92, y: h * 0.55),
                                controlPoint: CGPoint(x: w * 0.5, y: -h * 0.2))
            banana.addQuadCurve(to: CGPoint(x: w * 0.08, y: h * 0.55),
                                controlPoint: CGPoint(x: w * 0.5, y: h * 1.1))
            banana.fill()

            // Darker inner curve (belly)
            UIColor(red: 0.9, green: 0.78, blue: 0.12, alpha: 1).setFill()
            let belly = UIBezierPath()
            belly.move(to: CGPoint(x: w * 0.15, y: h * 0.55))
            belly.addQuadCurve(to: CGPoint(x: w * 0.85, y: h * 0.55),
                               controlPoint: CGPoint(x: w * 0.5, y: h * 0.85))
            belly.addQuadCurve(to: CGPoint(x: w * 0.15, y: h * 0.55),
                               controlPoint: CGPoint(x: w * 0.5, y: h * 0.45))
            belly.fill()

            // Highlight streak (top curve)
            UIColor(red: 1, green: 0.95, blue: 0.5, alpha: 0.6).setFill()
            let highlight = UIBezierPath()
            highlight.move(to: CGPoint(x: w * 0.25, y: h * 0.32))
            highlight.addQuadCurve(to: CGPoint(x: w * 0.75, y: h * 0.32),
                                   controlPoint: CGPoint(x: w * 0.5, y: h * 0.08))
            highlight.addQuadCurve(to: CGPoint(x: w * 0.25, y: h * 0.32),
                                   controlPoint: CGPoint(x: w * 0.5, y: h * 0.28))
            highlight.fill()

            // Brown stem tip (right end)
            UIColor(red: 0.45, green: 0.3, blue: 0.1, alpha: 1).setFill()
            UIBezierPath(ovalIn: CGRect(x: w * 0.86, y: h * 0.35, width: w * 0.1, height: h * 0.18)).fill()

            // Brown bottom tip (left end)
            UIColor(red: 0.35, green: 0.22, blue: 0.08, alpha: 1).setFill()
            UIBezierPath(ovalIn: CGRect(x: w * 0.04, y: h * 0.4, width: w * 0.08, height: h * 0.15)).fill()

            // Spots (overripe)
            UIColor(red: 0.5, green: 0.35, blue: 0.05, alpha: 0.35).setFill()
            UIBezierPath(ovalIn: CGRect(x: w * 0.35, y: h * 0.3, width: w * 0.05, height: h * 0.08)).fill()
            UIBezierPath(ovalIn: CGRect(x: w * 0.55, y: h * 0.35, width: w * 0.04, height: h * 0.06)).fill()
            UIBezierPath(ovalIn: CGRect(x: w * 0.45, y: h * 0.48, width: w * 0.06, height: h * 0.07)).fill()
        }
        return SKTexture(image: image)
    }
}
