import SpriteKit

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

    private func setupRoad(sceneSize: CGSize) {
        let rc = theme.roadColor
        let roadColor = UIColor(red: rc.r, green: rc.g, blue: rc.b, alpha: 1.0)

        // Create two wide road tiles for seamless scrolling
        for i in 0..<2 {
            let tile = SKSpriteNode(color: roadColor, size: CGSize(width: sceneSize.width * 2, height: trackHeight))
            tile.position = CGPoint(x: CGFloat(i) * sceneSize.width * 2, y: trackYOffset + trackHeight / 2)
            tile.anchorPoint = CGPoint(x: 0, y: 0.5)
            tile.zPosition = ZPositions.track
            addChild(tile)
            roadTiles.append(tile)
        }
    }

    private func setupLaneMarkers(sceneSize: CGSize) {
        let laneCount = GameConstants.laneCount
        let laneHeight = trackHeight / CGFloat(laneCount)

        for lane in 1..<laneCount {
            let y = trackYOffset + CGFloat(lane) * laneHeight
            for i in 0..<30 {
                let dash = SKShapeNode(rectOf: CGSize(width: 30, height: 2))
                dash.fillColor = .white
                dash.strokeColor = .clear
                dash.alpha = 0.3
                dash.position = CGPoint(x: CGFloat(i) * 80, y: y)
                dash.zPosition = ZPositions.laneMarkers
                dash.name = "laneMarker"
                addChild(dash)
                laneMarkers.append(dash)
            }
        }
    }

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
