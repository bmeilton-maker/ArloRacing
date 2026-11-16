import SpriteKit
import UIKit

class TrackNode: SKNode {
    let trackHeight: CGFloat
    let trackYOffset: CGFloat
    let theme: TrackTheme

    private var roadTiles: [SKSpriteNode] = []
    private var laneMarkers: [SKShapeNode] = []

    init(sceneSize: CGSize, theme: TrackTheme) {
        self.theme = theme
        // Track takes up middle 70% of screen height
        self.trackHeight = sceneSize.height * 0.7
        self.trackYOffset = sceneSize.height * 0.15

        super.init()
        self.name = "trackNode"
        self.zPosition = ZPositions.track

        setupRoad(sceneSize: sceneSize)
        setupLaneMarkers(sceneSize: sceneSize)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Road

    private func setupRoad(sceneSize: CGSize) {
        // Curb/shoulder strips live just outside the drivable band, baked
        // into the same texture so no extra nodes are needed. The sprite is
        // taller than trackHeight but still centered on the same Y, so the
        // asphalt band lines up exactly with trackYOffset...trackYOffset+trackHeight.
        let curbHeight = trackHeight * 0.07
        let edgeLineHeight = max(2, trackHeight * 0.012)
        let totalTexHeight = trackHeight + curbHeight * 2
        let tileWidth = sceneSize.width * 2

        let texture = makeRoadTexture(
            width: tileWidth,
            totalHeight: totalTexHeight,
            curbHeight: curbHeight,
            edgeLineHeight: edgeLineHeight
        )

        for i in 0..<2 {
            let tile = SKSpriteNode(texture: texture, size: CGSize(width: tileWidth, height: totalTexHeight))
            tile.position = CGPoint(x: CGFloat(i) * tileWidth, y: trackYOffset + trackHeight / 2)
            tile.anchorPoint = CGPoint(x: 0, y: 0.5)
            tile.zPosition = ZPositions.track
            addChild(tile)
            roadTiles.append(tile)
        }
    }

    private func makeRoadTexture(width: CGFloat, totalHeight: CGFloat, curbHeight: CGFloat, edgeLineHeight: CGFloat) -> SKTexture {
        let rc = theme.roadColor
        let baseColor = UIColor(red: rc.r, green: rc.g, blue: rc.b, alpha: 1.0)
        let ec = theme.roadEdgeColor
        let edgeColor = UIColor(red: ec.r, green: ec.g, blue: ec.b, alpha: 1.0)

        let format = UIGraphicsImageRendererFormat()
        format.opaque = true
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: width, height: totalHeight), format: format)

        let image = renderer.image { ctx in
            let cg = ctx.cgContext

            // 1. Base asphalt fill across the whole texture (curb bands paint over it next).
            baseColor.setFill()
            cg.fill(CGRect(x: 0, y: 0, width: width, height: totalHeight))

            // 2. Subtle darker/lighter asphalt patches, confined to the drivable band.
            let bandY = curbHeight
            let bandH = totalHeight - curbHeight * 2
            for _ in 0..<max(4, Int(width / 60)) {
                let px = CGFloat.random(in: 0...width)
                let py = bandY + CGFloat.random(in: 0...bandH)
                let radius = CGFloat.random(in: 12...30)
                let darker = Bool.random()
                let tint: UIColor = darker
                    ? UIColor(red: rc.r * 0.85, green: rc.g * 0.85, blue: rc.b * 0.85, alpha: 0.35)
                    : UIColor(red: min(1, rc.r * 1.15), green: min(1, rc.g * 1.15), blue: min(1, rc.b * 1.15), alpha: 0.25)
                tint.setFill()
                UIBezierPath(ovalIn: CGRect(x: px - radius, y: py - radius / 1.6, width: radius * 2, height: radius * 1.25)).fill()
            }

            // 3. Curb bands (alternating blocks) just outside the drivable band.
            let curbBlock: CGFloat = 36
            let blockCount = max(1, Int(width / curbBlock))
            let evenBlockW = width / CGFloat(blockCount)
            for i in 0..<blockCount {
                let isLight = i % 2 == 0
                let blockColor = isLight ? edgeColor : UIColor(red: rc.r * 0.5, green: rc.g * 0.5, blue: rc.b * 0.5, alpha: 1.0)
                blockColor.setFill()
                let bx = CGFloat(i) * evenBlockW
                cg.fill(CGRect(x: bx, y: 0, width: evenBlockW, height: curbHeight))
                cg.fill(CGRect(x: bx, y: totalHeight - curbHeight, width: evenBlockW, height: curbHeight))
            }

            // 4. Bright edge lines right at the curb/asphalt boundary, drawn last so they stay crisp.
            edgeColor.setFill()
            cg.fill(CGRect(x: 0, y: curbHeight, width: width, height: edgeLineHeight))
            cg.fill(CGRect(x: 0, y: totalHeight - curbHeight - edgeLineHeight, width: width, height: edgeLineHeight))
        }
        return SKTexture(image: image)
    }

    // MARK: - Lane markers

    private func setupLaneMarkers(sceneSize: CGSize) {
        let laneCount = GameConstants.laneCount
        let laneHeight = trackHeight / CGFloat(laneCount)

        // Rounded, theme-tinted-white dashes: blend white with a touch of
        // the theme's edge color so lanes feel native to each track.
        let ec = theme.roadEdgeColor
        let dashColor = UIColor(red: 0.6 + ec.r * 0.4, green: 0.6 + ec.g * 0.4, blue: 0.6 + ec.b * 0.4, alpha: 1.0)

        for lane in 1..<laneCount {
            let y = trackYOffset + CGFloat(lane) * laneHeight
            for i in 0..<30 {
                let dash = SKShapeNode(rectOf: CGSize(width: 32, height: 4), cornerRadius: 2)
                dash.fillColor = dashColor
                dash.strokeColor = .clear
                dash.alpha = 0.55
                dash.position = CGPoint(x: CGFloat(i) * 80, y: y)
                dash.zPosition = ZPositions.laneMarkers
                dash.name = "laneMarker"
                addChild(dash)
                laneMarkers.append(dash)
            }
        }
    }

    // MARK: - Update (mechanics unchanged)

    func update(scrollAmount: CGFloat, sceneWidth: CGFloat) {
        for tile in roadTiles {
            tile.position.x -= scrollAmount
            if tile.position.x + tile.size.width < -sceneWidth {
                tile.position.x += tile.size.width * 2
            }
        }

        for marker in laneMarkers {
            marker.position.x -= scrollAmount
            if marker.position.x < -50 {
                marker.position.x += 80 * 30
            }
        }
    }

    func laneYPosition(lane: Int) -> CGFloat {
        let laneHeight = trackHeight / CGFloat(GameConstants.laneCount)
        return trackYOffset + (CGFloat(lane) + 0.5) * laneHeight
    }
}
