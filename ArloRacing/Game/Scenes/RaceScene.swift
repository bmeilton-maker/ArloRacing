import SpriteKit
import SwiftUI

class RaceScene: SKScene, SKPhysicsContactDelegate {
    var gameState: GameState!

    private var carNode: CarNode!
    private var worldNode: SKNode!
    private var trackNode: TrackNode!
    private var hudNode: HUDNode!
    private var obstacleContainer: SKNode!
    private var finishLineNode: SKSpriteNode!
    private var effectsLayer: SKNode!

    private var inputController = InputController()
    private var vehiclePhysics: VehiclePhysics!
    private var timing = TimingSystem()
    private var trackGenerator: TrackGenerator!

    private var oncomingContainer: SKNode!

    private var distanceTraveled: CGFloat = 0
    private var trackLength: CGFloat = 0
    private var raceStarted = false
    private var raceFinished = false

    private var lastUpdateTime: TimeInterval = 0

    private var backgroundLayers: [SKSpriteNode] = []
    private var speedLineEmitter: SKNode?
    private var speedLineIntensity: CGFloat = 0

    private var cameraNode2: SKCameraNode! // named to avoid conflict with SKScene.camera

    // Parallax speeds
    private let parallaxSpeeds: [CGFloat] = [0.1, 0.3, 0.6]

    // Enhancement 1: Near-miss dodge system
    private var currentCombo: Int = 0
    private var dodgedObstacleIDs: Set<ObjectIdentifier> = []
    private var dodgedOncomingIDs: Set<ObjectIdentifier> = []

    // Enhancement 2: Dust puff timing
    private var lastDustTime: TimeInterval = 0

    // Enhancement 3: Car tilt
    private var currentTilt: CGFloat = 0

    // Enhancement 3: Finish line pulse state
    private var finishLinePulsing = false
    private var checkerNodes: [SKSpriteNode] = []

    override func didMove(to view: SKView) {
        guard let track = gameState.selectedTrack,
              let vehicle = gameState.selectedVehicle else {
            assertionFailure("RaceScene presented without a selected track/vehicle")
            return
        }

        trackLength = track.length
        vehiclePhysics = VehiclePhysics(vehicle: vehicle, trackModifier: track.maxSpeedModifier)
        trackGenerator = TrackGenerator(seed: track.seed)

        inputController.configure(sceneSize: size)

        setupBackground(theme: track.theme)
        setupCamera()
        PhysicsController.setupPhysicsWorld(self)
        physicsWorld.contactDelegate = self

        setupWorld(track: track)
        setupCar()
        setupHUD()

        startCountdown()
    }

    // MARK: - Setup

    private func setupBackground(theme: TrackTheme) {
        let top = theme.skyTopColor
        self.backgroundColor = UIColor(red: top.r, green: top.g, blue: top.b, alpha: 1.0)

        // Sky: full-scene gradient, compressed so the horizon color sits
        // just above the road band (the visible sky is the top ~15%).
        let sky = SKSpriteNode(texture: Self.skyTexture(size: size, theme: theme), size: size)
        sky.position = CGPoint(x: size.width / 2, y: size.height / 2)
        sky.zPosition = ZPositions.background - 4
        addChild(sky)

        // Sun (or moon for night) with a soft glow, upper right.
        addCelestialBody(theme: theme)

        // Ground strip between the road's top curb and the horizon.
        let groundC = theme.groundColor
        let upperGround = SKSpriteNode(
            color: UIColor(red: groundC.r, green: groundC.g, blue: groundC.b, alpha: 1.0),
            size: CGSize(width: size.width, height: size.height * 0.09)
        )
        upperGround.anchorPoint = CGPoint(x: 0, y: 0)
        upperGround.position = CGPoint(x: 0, y: size.height * 0.84)
        upperGround.zPosition = ZPositions.background - 1
        addChild(upperGround)

        // Foreground ground below the road (slightly darker for depth).
        let lowerGround = SKSpriteNode(
            color: UIColor(red: groundC.r * 0.82, green: groundC.g * 0.82, blue: groundC.b * 0.82, alpha: 1.0),
            size: CGSize(width: size.width, height: size.height * 0.16)
        )
        lowerGround.anchorPoint = CGPoint(x: 0, y: 0)
        lowerGround.position = CGPoint(x: 0, y: 0)
        lowerGround.zPosition = ZPositions.background - 1
        addChild(lowerGround)

        // Three parallax layers, two tiles each. INVARIANT (update() relies
        // on it): anchorPoint.x == 0, tile width == 2 × scene width, pair
        // offset by tile width; wrap adds width * 2.
        let tileWidth = size.width * 2
        let bandHeight = size.height * 0.16

        let farTexture = Self.sceneryTexture(theme: theme, width: tileWidth, height: bandHeight, near: false)
        let nearTexture = Self.sceneryTexture(theme: theme, width: tileWidth, height: bandHeight * 0.72, near: true)
        let detailTexture = Self.foregroundDetailTexture(theme: theme, width: tileWidth, height: size.height * 0.12)

        let layerSpecs: [(texture: SKTexture, height: CGFloat, y: CGFloat, z: CGFloat)] = [
            (farTexture, bandHeight, size.height * 0.855, ZPositions.background),          // speed 0.1
            (nearTexture, bandHeight * 0.72, size.height * 0.845, ZPositions.background + 1), // speed 0.3
            (detailTexture, size.height * 0.12, size.height * 0.005, ZPositions.background + 2), // speed 0.6
        ]

        for spec in layerSpecs {
            for j in 0..<2 {
                let layer = SKSpriteNode(texture: spec.texture, size: CGSize(width: tileWidth, height: spec.height))
                layer.anchorPoint = CGPoint(x: 0, y: 0)
                layer.position = CGPoint(x: CGFloat(j) * tileWidth, y: spec.y)
                layer.zPosition = spec.z
                addChild(layer)
                backgroundLayers.append(layer)
            }
        }

        // Ambient atmosphere: twinkling stars at night, falling snow in the arctic.
        if theme == .night { addStars() }
        if theme == .arctic { addSnowfall() }
    }

    private func addCelestialBody(theme: TrackTheme) {
        let cc = theme.celestialColor
        let color = UIColor(red: cc.r, green: cc.g, blue: cc.b, alpha: 1.0)
        let radius: CGFloat = theme == .night ? 14 : 18
        let center = CGPoint(x: size.width * 0.82, y: size.height * 0.93)

        let glow = SKShapeNode(circleOfRadius: radius * 2.2)
        glow.fillColor = color.withAlphaComponent(0.18)
        glow.strokeColor = .clear
        glow.position = center
        glow.zPosition = ZPositions.background - 3
        addChild(glow)

        let body = SKShapeNode(circleOfRadius: radius)
        body.fillColor = color
        body.strokeColor = .clear
        body.position = center
        body.zPosition = ZPositions.background - 3
        addChild(body)

        if theme == .night {
            // Crescent shadow bite for the moon
            let bite = SKShapeNode(circleOfRadius: radius * 0.85)
            let sky = theme.skyTopColor
            bite.fillColor = UIColor(red: sky.r, green: sky.g, blue: sky.b, alpha: 1.0)
            bite.strokeColor = .clear
            bite.position = CGPoint(x: center.x - radius * 0.45, y: center.y + radius * 0.3)
            bite.zPosition = ZPositions.background - 3
            addChild(bite)
        }
    }

    private func addStars() {
        for _ in 0..<18 {
            let star = SKShapeNode(circleOfRadius: CGFloat.random(in: 0.8...1.8))
            star.fillColor = .white
            star.strokeColor = .clear
            star.position = CGPoint(
                x: CGFloat.random(in: 0...size.width),
                y: CGFloat.random(in: size.height * 0.87...size.height * 0.99)
            )
            star.alpha = CGFloat.random(in: 0.3...0.9)
            star.zPosition = ZPositions.background - 3
            addChild(star)

            let twinkle = SKAction.sequence([
                SKAction.fadeAlpha(to: 0.15, duration: Double.random(in: 0.8...1.8)),
                SKAction.fadeAlpha(to: 0.9, duration: Double.random(in: 0.8...1.8)),
            ])
            star.run(SKAction.repeatForever(twinkle))
        }
    }

    private func addSnowfall() {
        for _ in 0..<16 {
            let flake = SKShapeNode(circleOfRadius: CGFloat.random(in: 1.2...2.6))
            flake.fillColor = UIColor(white: 1.0, alpha: 0.7)
            flake.strokeColor = .clear
            let startX = CGFloat.random(in: 0...size.width)
            flake.position = CGPoint(x: startX, y: CGFloat.random(in: 0...size.height))
            flake.zPosition = ZPositions.effects - 1
            addChild(flake)

            let duration = Double.random(in: 4.5...8.0)
            let fall = SKAction.sequence([
                SKAction.moveBy(x: CGFloat.random(in: -70 ... -30), y: -size.height - 20, duration: duration),
                SKAction.run { [weak flake] in
                    flake?.position = CGPoint(x: CGFloat.random(in: 0...(flake?.scene?.size.width ?? 800)), y: (flake?.scene?.size.height ?? 400) + 10)
                },
            ])
            flake.run(SKAction.repeatForever(fall))
        }
    }

    // MARK: - Background texture generation (rendered once per race)

    private static func skyTexture(size: CGSize, theme: TrackTheme) -> SKTexture {
        let top = theme.skyTopColor
        let horizon = theme.skyHorizonColor
        let format = UIGraphicsImageRendererFormat()
        format.opaque = true
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        let image = renderer.image { ctx in
            let colors = [
                UIColor(red: top.r, green: top.g, blue: top.b, alpha: 1).cgColor,
                UIColor(red: horizon.r, green: horizon.g, blue: horizon.b, alpha: 1).cgColor,
            ] as CFArray
            // Horizon color reached ~18% down the image (just above the road)
            let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: [0.0, 0.18])!
            ctx.cgContext.drawLinearGradient(
                gradient,
                start: .zero,
                end: CGPoint(x: 0, y: size.height),
                options: [.drawsAfterEndLocation]
            )
        }
        return SKTexture(image: image)
    }

    /// Silhouette scenery band. `near == false` draws the far layer
    /// (dunes / treeline / skyline / peaks); `near == true` draws closer,
    /// darker motifs (cacti / bushes / lamps / drifts). Motifs keep clear of
    /// the tile edges so the two-tile wrap never shows a seam.
    private static func sceneryTexture(theme: TrackTheme, width: CGFloat, height: CGFloat, near: Bool) -> SKTexture {
        let c = near ? theme.sceneryNearColor : theme.sceneryFarColor
        let color = UIColor(red: c.r, green: c.g, blue: c.b, alpha: 1.0)
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: width, height: height))
        let image = renderer.image { _ in
            color.setFill()
            // UIKit y=0 is the TOP of the image; the band's bottom is y=height.
            let baseline = height

            switch (theme, near) {
            case (.desert, false):
                // Rolling dunes: broad overlapping half-ellipses
                var x: CGFloat = 60
                while x < width - 160 {
                    let w = CGFloat.random(in: 180...320)
                    let h = CGFloat.random(in: height * 0.35...height * 0.7)
                    UIBezierPath(ovalIn: CGRect(x: x, y: baseline - h, width: w, height: h * 2)).fill()
                    x += w * CGFloat.random(in: 0.55...0.8)
                }
            case (.desert, true):
                // Cacti and rocks
                var x: CGFloat = 80
                while x < width - 120 {
                    if Bool.random() {
                        let h = CGFloat.random(in: height * 0.5...height * 0.85)
                        UIBezierPath(roundedRect: CGRect(x: x, y: baseline - h, width: 7, height: h), cornerRadius: 3).fill()
                        UIBezierPath(roundedRect: CGRect(x: x - 7, y: baseline - h * 0.65, width: 7, height: h * 0.3), cornerRadius: 3).fill()
                        UIBezierPath(roundedRect: CGRect(x: x + 7, y: baseline - h * 0.75, width: 7, height: h * 0.35), cornerRadius: 3).fill()
                    } else {
                        let w = CGFloat.random(in: 16...30)
                        UIBezierPath(ovalIn: CGRect(x: x, y: baseline - w * 0.5, width: w, height: w)).fill()
                    }
                    x += CGFloat.random(in: 130...260)
                }
            case (.forest, false), (.arctic, false):
                // Jagged peaks / treeline
                let peakCount = Int(width / 90)
                let path = UIBezierPath()
                path.move(to: CGPoint(x: 40, y: baseline))
                for i in 0..<peakCount {
                    let px = 40 + CGFloat(i) * ((width - 80) / CGFloat(peakCount))
                    let peakH = CGFloat.random(in: height * 0.4...height * 0.9)
                    path.addLine(to: CGPoint(x: px + 45, y: baseline - peakH))
                    path.addLine(to: CGPoint(x: px + 90, y: baseline - CGFloat.random(in: 0...height * 0.2)))
                }
                path.addLine(to: CGPoint(x: width - 40, y: baseline))
                path.close()
                path.fill()
                if theme == .arctic {
                    // Snow caps
                    UIColor(white: 1.0, alpha: 0.85).setFill()
                    for i in 0..<peakCount {
                        let px = 40 + CGFloat(i) * ((width - 80) / CGFloat(peakCount)) + 45
                        UIBezierPath(ovalIn: CGRect(x: px - 12, y: baseline - height * 0.88, width: 24, height: 9)).fill()
                    }
                }
            case (.forest, true):
                // Bushes and simple pines
                var x: CGFloat = 70
                while x < width - 120 {
                    if Bool.random() {
                        let h = CGFloat.random(in: height * 0.5...height * 0.9)
                        let tree = UIBezierPath()
                        tree.move(to: CGPoint(x: x, y: baseline))
                        tree.addLine(to: CGPoint(x: x + 14, y: baseline - h))
                        tree.addLine(to: CGPoint(x: x + 28, y: baseline))
                        tree.close()
                        tree.fill()
                    } else {
                        let w = CGFloat.random(in: 24...44)
                        UIBezierPath(ovalIn: CGRect(x: x, y: baseline - w * 0.4, width: w, height: w * 0.8)).fill()
                    }
                    x += CGFloat.random(in: 90...200)
                }
            case (.urban, false), (.night, false):
                // City skyline with lit windows
                var x: CGFloat = 50
                while x < width - 150 {
                    let bw = CGFloat.random(in: 45...90)
                    let bh = CGFloat.random(in: height * 0.35...height * 0.95)
                    color.setFill()
                    UIBezierPath(rect: CGRect(x: x, y: baseline - bh, width: bw, height: bh)).fill()
                    // Windows — brighter at night
                    UIColor(red: 1.0, green: 0.9, blue: 0.5, alpha: theme == .night ? 0.85 : 0.35).setFill()
                    var wy = baseline - bh + 6
                    while wy < baseline - 8 {
                        var wx = x + 5
                        while wx < x + bw - 6 {
                            if Bool.random() {
                                UIBezierPath(rect: CGRect(x: wx, y: wy, width: 3.5, height: 4.5)).fill()
                            }
                            wx += 9
                        }
                        wy += 11
                    }
                    x += bw + CGFloat.random(in: 8...40)
                }
            case (.urban, true), (.night, true):
                // Lamp posts and low walls
                var x: CGFloat = 90
                while x < width - 120 {
                    color.setFill()
                    if Bool.random() {
                        let h = height * 0.8
                        UIBezierPath(rect: CGRect(x: x, y: baseline - h, width: 4, height: h)).fill()
                        UIColor(red: 1.0, green: 0.95, blue: 0.7, alpha: 0.9).setFill()
                        UIBezierPath(ovalIn: CGRect(x: x - 3, y: baseline - h - 6, width: 10, height: 8)).fill()
                    } else {
                        UIBezierPath(roundedRect: CGRect(x: x, y: baseline - height * 0.3, width: CGFloat.random(in: 40...80), height: height * 0.3), cornerRadius: 3).fill()
                    }
                    x += CGFloat.random(in: 150...300)
                }
            case (.arctic, true):
                // Snow drifts and small pines
                var x: CGFloat = 60
                while x < width - 140 {
                    if Bool.random() {
                        let w = CGFloat.random(in: 60...120)
                        UIBezierPath(ovalIn: CGRect(x: x, y: baseline - height * 0.3, width: w, height: height * 0.6)).fill()
                    } else {
                        let h = CGFloat.random(in: height * 0.5...height * 0.8)
                        let tree = UIBezierPath()
                        tree.move(to: CGPoint(x: x, y: baseline))
                        tree.addLine(to: CGPoint(x: x + 12, y: baseline - h))
                        tree.addLine(to: CGPoint(x: x + 24, y: baseline))
                        tree.close()
                        tree.fill()
                        UIColor(white: 1.0, alpha: 0.5).setFill()
                        UIBezierPath(ovalIn: CGRect(x: x + 6, y: baseline - h, width: 12, height: 5)).fill()
                        color.setFill()
                    }
                    x += CGFloat.random(in: 110...240)
                }
            }
        }
        return SKTexture(image: image)
    }

    /// Fast-scrolling speckle strip for the foreground band below the road.
    private static func foregroundDetailTexture(theme: TrackTheme, width: CGFloat, height: CGFloat) -> SKTexture {
        let g = theme.groundColor
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: width, height: height))
        let image = renderer.image { _ in
            for _ in 0..<Int(width / 22) {
                let dark = Bool.random()
                let factor: CGFloat = dark ? 0.65 : 1.15
                UIColor(
                    red: min(1, g.r * factor),
                    green: min(1, g.g * factor),
                    blue: min(1, g.b * factor),
                    alpha: 0.55
                ).setFill()
                let w = CGFloat.random(in: 5...16)
                UIBezierPath(ovalIn: CGRect(
                    x: CGFloat.random(in: 20...(width - 40)),
                    y: CGFloat.random(in: 0...(height - 6)),
                    width: w,
                    height: w * 0.4
                )).fill()
            }
        }
        return SKTexture(image: image)
    }

    private func setupCamera() {
        cameraNode2 = SKCameraNode()
        cameraNode2.position = CGPoint(x: size.width / 2, y: size.height / 2)
        addChild(cameraNode2)
        self.camera = cameraNode2
    }

    private func setupWorld(track: Track) {
        worldNode = SKNode()
        worldNode.name = "worldNode"
        addChild(worldNode)

        // Track road surface
        trackNode = TrackNode(sceneSize: size, theme: track.theme)
        worldNode.addChild(trackNode)

        // Obstacles
        obstacleContainer = SKNode()
        obstacleContainer.name = "obstacleContainer"
        worldNode.addChild(obstacleContainer)

        let obstacles = trackGenerator.generateObstacles(
            density: track.obstacleDensity,
            trackLength: track.length,
            laneCount: GameConstants.laneCount
        )

        let carStartX = size.width * GameConstants.carScreenXRatio

        for data in obstacles {
            let node = ObstacleNode(type: data.type)
            let yPos = trackNode.laneYPosition(lane: data.lane)
            node.position = CGPoint(x: data.x + carStartX, y: yPos)
            PhysicsController.setupObstaclePhysics(node)
            obstacleContainer.addChild(node)

            // Enhancement 3: Obstacle bobbing animation
            let bobUp = SKAction.moveBy(x: 0, y: 2, duration: 0.6)
            let bobDown = SKAction.moveBy(x: 0, y: -2, duration: 0.6)
            bobUp.timingMode = .easeInEaseOut
            bobDown.timingMode = .easeInEaseOut
            let bobDelay = SKAction.wait(forDuration: Double.random(in: 0...0.5))
            node.run(SKAction.sequence([bobDelay, SKAction.repeatForever(SKAction.sequence([bobUp, bobDown]))]))
        }

        // Oncoming cars
        oncomingContainer = SKNode()
        oncomingContainer.name = "oncomingContainer"
        worldNode.addChild(oncomingContainer)

        let oncomingCars = trackGenerator.generateOncomingCars(trackLength: track.length, laneCount: GameConstants.laneCount)
        for data in oncomingCars {
            let node = OncomingCarNode.create(lane: data.lane, trackNode: trackNode, vehicleType: data.vehicleType)
            node.position.x = data.x + carStartX
            node.oncomingSpeed = data.speed
            PhysicsController.setupOncomingCarPhysics(node)
            oncomingContainer.addChild(node)
        }

        // Finish line
        finishLineNode = SKSpriteNode(color: .clear, size: CGSize(width: 20, height: trackNode.trackHeight))
        finishLineNode.name = "finishLine"
        finishLineNode.position = CGPoint(x: track.length + carStartX, y: trackNode.trackYOffset + trackNode.trackHeight / 2)
        PhysicsController.setupFinishLinePhysics(finishLineNode)
        worldNode.addChild(finishLineNode)

        // Visual finish line (checkered)
        let checkerSize: CGFloat = 15
        let rows = Int(trackNode.trackHeight / checkerSize)
        let cols = 4
        for row in 0..<rows {
            for col in 0..<cols {
                let isWhite = (row + col) % 2 == 0
                let checker = SKSpriteNode(color: isWhite ? .white : .black, size: CGSize(width: checkerSize, height: checkerSize))
                checker.position = CGPoint(
                    x: finishLineNode.position.x - CGFloat(cols) * checkerSize / 2 + CGFloat(col) * checkerSize + checkerSize / 2,
                    y: trackNode.trackYOffset + CGFloat(row) * checkerSize + checkerSize / 2
                )
                checker.zPosition = ZPositions.obstacles
                worldNode.addChild(checker)
                checkerNodes.append(checker)
            }
        }

        // "FINISH" banner floating above the checkered line (child of
        // worldNode, so the generic world-scroll loop carries it along).
        let bannerPanel = SKShapeNode(rectOf: CGSize(width: 96, height: 26), cornerRadius: 6)
        bannerPanel.fillColor = UIColor(white: 0.08, alpha: 0.85)
        bannerPanel.strokeColor = UIColor(white: 1.0, alpha: 0.5)
        bannerPanel.lineWidth = 1.5
        bannerPanel.position = CGPoint(
            x: finishLineNode.position.x,
            y: trackNode.trackYOffset + trackNode.trackHeight + 22
        )
        bannerPanel.zPosition = ZPositions.obstacles
        let bannerLabel = SKLabelNode(fontNamed: "Menlo-Bold")
        bannerLabel.text = "FINISH"
        bannerLabel.fontSize = 15
        bannerLabel.fontColor = .white
        bannerLabel.verticalAlignmentMode = .center
        bannerPanel.addChild(bannerLabel)
        worldNode.addChild(bannerPanel)

        // Track bounds
        PhysicsController.setupTrackBounds(self, trackHeight: trackNode.trackHeight, yOffset: trackNode.trackYOffset)

        // Effects layer
        effectsLayer = SKNode()
        effectsLayer.zPosition = ZPositions.effects
        addChild(effectsLayer)
    }

    private func setupCar() {
        let vehicleId = gameState.selectedVehicle?.id ?? "sports"
        let color = gameState.vehicleColor

        carNode = CarNode.create(vehicleId: vehicleId, color: color)
        carNode.position = CGPoint(
            x: size.width * GameConstants.carScreenXRatio,
            y: size.height / 2
        )
        PhysicsController.setupCarPhysics(carNode)
        addChild(carNode)
    }

    private func setupHUD() {
        hudNode = HUDNode()
        hudNode.setup(sceneSize: size)
        addChild(hudNode)
    }

    // MARK: - Countdown

    private func startCountdown() {
        gameState.isCountingDown = true
        raceStarted = false

        let countTexts = ["3", "2", "1", "GO!"]
        var actions: [SKAction] = []

        for (i, text) in countTexts.enumerated() {
            actions.append(SKAction.run { [weak self] in
                self?.hudNode.showCountdown(text)
                if i < 3 {
                    AudioManager.shared.play(.countdownBeep)
                } else {
                    AudioManager.shared.play(.raceStart)
                }
            })
            actions.append(SKAction.wait(forDuration: i < 3 ? 1.0 : 0.5))
        }

        actions.append(SKAction.run { [weak self] in
            self?.hudNode.hideCountdown()
            self?.gameState.isCountingDown = false
            self?.raceStarted = true
            self?.timing.start()
            AudioManager.shared.startEngine()
        })

        run(SKAction.sequence(actions), withKey: "countdown")
    }

    // MARK: - Update

    override func update(_ currentTime: TimeInterval) {
        if lastUpdateTime == 0 {
            lastUpdateTime = currentTime
            return
        }

        let dt = min(currentTime - lastUpdateTime, 1.0 / 30.0) // Cap at 30fps minimum
        lastUpdateTime = currentTime

        guard !raceFinished else { return }

        if gameState.isPaused {
            return
        }

        guard raceStarted else { return }

        // Update physics
        let throttle = inputController.isActive ? inputController.currentInput.throttle : 0
        vehiclePhysics.update(deltaTime: dt, throttle: throttle, fingerDown: inputController.isActive)

        // Advance the race clock with the same dt that moves the world
        timing.tick(dt)

        // Update car vertical position (steering).
        // gripFactor is already reduced while slipping (see applyBananaHit).
        let steerInput = inputController.currentInput.steer
        if inputController.isActive {
            let steerAmount = steerInput * GameConstants.steerSensitivity * vehiclePhysics.gripFactor
            let targetY = carNode.position.y + steerAmount
            let minY = trackNode.trackYOffset + carNode.size.height / 2
            let maxY = trackNode.trackYOffset + trackNode.trackHeight - carNode.size.height / 2
            let clampedY = clamp(targetY, min: minY, max: maxY)
            carNode.position.y = CGFloat.lerp(carNode.position.y, clampedY, t: GameConstants.steerSmoothing)
        }
        // Steer is a per-touch-move delta; consume it so a stationary finger
        // doesn't keep applying the last delta every frame (drift bug).
        inputController.consumeSteer()

        // Scroll world
        let scrollAmount = vehiclePhysics.currentSpeed * CGFloat(dt)
        distanceTraveled += scrollAmount

        // Scroll track
        trackNode.update(scrollAmount: scrollAmount, sceneWidth: size.width)

        // Scroll each obstacle individually so dynamic physics bodies update
        for child in obstacleContainer.children {
            child.position.x -= scrollAmount
        }

        // Scroll oncoming cars — they also move toward the player under their own speed
        for child in oncomingContainer.children {
            if let oncoming = child as? OncomingCarNode {
                let totalScroll = scrollAmount + oncoming.oncomingSpeed * CGFloat(dt)
                oncoming.position.x -= totalScroll
            }
            // Remove if off-screen left
            if child.position.x < -100 {
                child.removeFromParent()
            }
        }

        // Scroll finish line
        finishLineNode.position.x -= scrollAmount

        // Scroll checkers and other worldNode children
        for child in worldNode.children {
            if child !== trackNode && child !== obstacleContainer && child !== oncomingContainer && child !== finishLineNode {
                child.position.x -= scrollAmount
            }
        }

        // Parallax background scroll
        for (index, layer) in backgroundLayers.enumerated() {
            let pSpeed = parallaxSpeeds[index / 2]
            layer.position.x -= vehiclePhysics.currentSpeed * pSpeed * CGFloat(dt)
            if layer.position.x + layer.size.width < 0 {
                layer.position.x += layer.size.width * 2
            }
        }

        // Enhancement 3: Car tilt based on steering (uses the steer value
        // captured above, before it was consumed)
        if inputController.isActive && steerInput != 0 {
            let targetTilt = clamp(steerInput * -0.08, min: -0.15, max: 0.15)
            currentTilt = currentTilt + (targetTilt - currentTilt) * 0.12
        } else {
            currentTilt = currentTilt * 0.9 // Smoothly return to 0
        }
        carNode.zRotation = currentTilt

        // Enhancement 4: Track top speed
        if vehiclePhysics.currentSpeed > gameState.topSpeedReached {
            gameState.topSpeedReached = vehiclePhysics.currentSpeed
        }

        // Enhancement 1: Near-miss dodge detection
        checkNearMisses()

        // Enhancement 2: Dust puffs when accelerating
        if vehiclePhysics.currentSpeed > 10 && inputController.isActive && inputController.currentInput.throttle > 0.3 {
            if currentTime - lastDustTime > GameConstants.dustSpawnInterval {
                spawnDustPuff()
                lastDustTime = currentTime
            }
        }

        // Enhancement 2: Gradual speed lines (start at 50%, scale to 100%)
        if vehiclePhysics.speedRatio > 0.5 {
            // Update the live intensity every frame — the emitter closure
            // reads this, so the effect actually ramps with speed.
            speedLineIntensity = (vehiclePhysics.speedRatio - 0.5) / 0.5
            showSpeedLines()
        } else {
            hideSpeedLines()
        }

        // Enhancement 3: Finish line pulse when approaching
        if distanceTraveled > trackLength * 0.9 && !finishLinePulsing {
            startFinishLinePulse()
        }

        // Update HUD
        hudNode.updateTimer(timing.elapsedTime)
        hudNode.updateSpeed(vehiclePhysics.currentSpeed)
        hudNode.updateProgress(distanceTraveled / trackLength)
        hudNode.updateCombo(currentCombo)

        // Engine pitch
        AudioManager.shared.updateEnginePitch(speedRatio: Float(vehiclePhysics.speedRatio))

        // Finish is detected by physics contact with the finish line node
    }

    // MARK: - Near-Miss Detection (Enhancement 1)

    private func checkNearMisses() {
        let carPos = carNode.position
        let threshold = GameConstants.dodgeDistanceThreshold

        // Check obstacles
        for child in obstacleContainer.children {
            guard let obstacle = child as? ObstacleNode else { continue }
            let objID = ObjectIdentifier(obstacle)
            guard !dodgedObstacleIDs.contains(objID) else { continue }

            // Only check obstacles that are near the car's X position (within ~30 pts behind to ~30 ahead)
            let dx = obstacle.position.x - carPos.x
            guard dx > -30 && dx < 30 else { continue }

            let dy = abs(obstacle.position.y - carPos.y)
            if dy < threshold && dy > 15 { // Close but not touching (15 = approx collision radius)
                dodgedObstacleIDs.insert(objID)
                currentCombo += 1
                gameState.dodgeCount += 1
                if currentCombo > gameState.maxCombo {
                    gameState.maxCombo = currentCombo
                }
                showDodgePopup(at: CGPoint(x: obstacle.position.x, y: obstacle.position.y + 30))
                flashScreen(color: .white, alpha: 0.12, duration: 0.1)
            }
        }

        // Check oncoming cars
        for child in oncomingContainer.children {
            guard let oncoming = child as? OncomingCarNode else { continue }
            let objID = ObjectIdentifier(oncoming)
            guard !dodgedOncomingIDs.contains(objID) else { continue }

            let dx = oncoming.position.x - carPos.x
            guard dx > -40 && dx < 40 else { continue }

            let dy = abs(oncoming.position.y - carPos.y)
            if dy < threshold + 10 && dy > 20 {
                dodgedOncomingIDs.insert(objID)
                currentCombo += 1
                gameState.dodgeCount += 1
                if currentCombo > gameState.maxCombo {
                    gameState.maxCombo = currentCombo
                }
                showDodgePopup(at: CGPoint(x: oncoming.position.x, y: oncoming.position.y + 30))
                flashScreen(color: .white, alpha: 0.15, duration: 0.1)
            }
        }
    }

    private func showDodgePopup(at position: CGPoint) {
        let text = currentCombo > 1 ? "+DODGE x\(currentCombo)!" : "+DODGE!"
        let label = SKLabelNode(fontNamed: "Menlo-Bold")
        label.text = text
        label.fontSize = currentCombo > 3 ? 18 : 14
        label.fontColor = currentCombo > 3 ? .yellow : .white
        label.position = position
        label.zPosition = ZPositions.effects + 5
        addChild(label)

        let floatUp = SKAction.moveBy(x: 0, y: 40, duration: 0.6)
        let fade = SKAction.fadeOut(withDuration: 0.4)
        let scaleUp = SKAction.scale(to: 1.3, duration: 0.15)
        let scaleBack = SKAction.scale(to: 1.0, duration: 0.1)
        label.run(SKAction.sequence([
            SKAction.group([
                floatUp,
                SKAction.sequence([SKAction.wait(forDuration: 0.3), fade]),
                SKAction.sequence([scaleUp, scaleBack])
            ]),
            SKAction.removeFromParent()
        ]))
    }

    private func flashScreen(color: UIColor, alpha: CGFloat, duration: TimeInterval) {
        let flash = SKSpriteNode(color: color, size: size)
        flash.position = CGPoint(x: size.width / 2, y: size.height / 2)
        flash.alpha = alpha
        flash.zPosition = ZPositions.hud - 1
        addChild(flash)
        flash.run(SKAction.sequence([
            SKAction.fadeOut(withDuration: duration),
            SKAction.removeFromParent()
        ]))
    }

    // MARK: - Dust Puffs (Enhancement 2)

    private func spawnDustPuff() {
        let puff = SKShapeNode(circleOfRadius: CGFloat.random(in: 3...6))
        puff.fillColor = UIColor(white: 0.6, alpha: 0.3)
        puff.strokeColor = .clear
        puff.position = CGPoint(
            x: carNode.position.x - carNode.size.width / 2 - 5,
            y: carNode.position.y + CGFloat.random(in: -8...8)
        )
        puff.zPosition = ZPositions.car - 1
        addChild(puff)

        puff.run(SKAction.sequence([
            SKAction.group([
                SKAction.moveBy(x: -30, y: CGFloat.random(in: -5...5), duration: 0.5),
                SKAction.fadeOut(withDuration: 0.5),
                SKAction.scale(to: 2.0, duration: 0.5)
            ]),
            SKAction.removeFromParent()
        ]))
    }

    // MARK: - Finish Line Pulse (Enhancement 3)

    private func startFinishLinePulse() {
        finishLinePulsing = true
        for checker in checkerNodes {
            let pulseOut = SKAction.fadeAlpha(to: 0.5, duration: 0.3)
            let pulseIn = SKAction.fadeAlpha(to: 1.0, duration: 0.3)
            checker.run(SKAction.repeatForever(SKAction.sequence([pulseOut, pulseIn])), withKey: "pulse")
        }
    }

    // MARK: - Speed Lines

    private func showSpeedLines() {
        guard speedLineEmitter == nil else { return }
        let container = SKNode()
        container.name = "speedLines"

        let repeat_ = SKAction.repeatForever(SKAction.sequence([
            SKAction.run { [weak self] in
                guard let self = self else { return }
                // Read the live intensity each burst so the effect ramps
                // from subtle at 50% speed to full at top speed.
                let intensity = self.speedLineIntensity
                let lineCount = max(1, Int(3 * intensity))
                let burstAlpha = 0.1 + 0.25 * intensity
                for _ in 0..<lineCount {
                    let line = SKShapeNode(rectOf: CGSize(width: CGFloat.random(in: 30...60), height: 1.5))
                    line.fillColor = UIColor(white: 1.0, alpha: burstAlpha)
                    line.strokeColor = .clear
                    line.position = CGPoint(x: self.size.width + 20, y: CGFloat.random(in: 0...self.size.height))
                    container.addChild(line)
                    line.run(SKAction.sequence([
                        SKAction.moveBy(x: -(self.size.width + 80), y: 0, duration: Double.random(in: 0.2...0.4)),
                        SKAction.removeFromParent()
                    ]))
                }
            },
            SKAction.wait(forDuration: 0.06)
        ]))
        container.run(repeat_, withKey: "speedLineLoop")

        effectsLayer.addChild(container)
        speedLineEmitter = container
    }

    private func hideSpeedLines() {
        speedLineEmitter?.removeFromParent()
        speedLineEmitter = nil
    }

    // MARK: - Finish

    private func finishRace() {
        raceFinished = true
        let finalTime = timing.stop()
        gameState.lastRaceTime = finalTime

        AudioManager.shared.stopEngine()
        AudioManager.shared.play(.finish)

        // Slow car to stop
        let slowDown = SKAction.customAction(withDuration: 1.5) { [weak self] _, elapsed in
            guard let self = self else { return }
            let ratio = 1.0 - (elapsed / 1.5)
            self.vehiclePhysics.currentSpeed = self.vehiclePhysics.maxSpeed * 0.5 * ratio
        }

        carNode.run(SKAction.sequence([
            slowDown,
            SKAction.run { [weak self] in
                self?.vehiclePhysics.currentSpeed = 0
                self?.gameState.isRaceComplete = true
            }
        ]))
    }

    // MARK: - Crash

    private func handleCrash() {
        raceFinished = true
        vehiclePhysics.currentSpeed = 0
        timing.stop()
        gameState.lastRaceTime = nil
        gameState.isCrashed = true

        AudioManager.shared.stopEngine()
        AudioManager.shared.play(.coneHit)

        // Enhancement 2: Intense camera shake
        cameraNode2.run(SKAction.shake(duration: 0.6, intensity: 12.0))

        // Enhancement 2: Crash explosion particles
        spawnCrashExplosion(at: carNode.position)

        // Enhancement 2: Red screen flash
        flashScreen(color: .red, alpha: 0.3, duration: 0.2)

        // Spin and fade the car
        let crash = SKAction.group([
            SKAction.rotate(byAngle: .pi * 3, duration: 0.8),
            SKAction.sequence([
                SKAction.scale(to: 1.3, duration: 0.15),
                SKAction.scale(to: 0.6, duration: 0.65)
            ])
        ])

        carNode.run(SKAction.sequence([
            crash,
            SKAction.wait(forDuration: 0.5),
            SKAction.run { [weak self] in
                self?.gameState.isRaceComplete = true
            }
        ]))
    }

    private func spawnCrashExplosion(at position: CGPoint) {
        let colors: [UIColor] = [.red, .orange, .yellow, .systemRed, .systemOrange]
        for _ in 0..<18 {
            let size = CGFloat.random(in: 4...12)
            let particle = SKShapeNode(circleOfRadius: size)
            particle.fillColor = colors.randomElement()!
            particle.strokeColor = .clear
            particle.position = position
            particle.zPosition = ZPositions.effects + 3
            particle.alpha = 0.9
            addChild(particle)

            let angle = CGFloat.random(in: 0...(2 * .pi))
            let distance = CGFloat.random(in: 40...120)
            let dx = cos(angle) * distance
            let dy = sin(angle) * distance

            particle.run(SKAction.sequence([
                SKAction.group([
                    SKAction.moveBy(x: dx, y: dy, duration: Double.random(in: 0.3...0.6)),
                    SKAction.fadeOut(withDuration: 0.5),
                    SKAction.scale(to: 0.1, duration: 0.5)
                ]),
                SKAction.removeFromParent()
            ]))
        }
    }

    // MARK: - Physics Contact

    func didBegin(_ contact: SKPhysicsContact) {
        let (bodyA, bodyB) = (contact.bodyA, contact.bodyB)
        let contactMask = bodyA.categoryBitMask | bodyB.categoryBitMask

        if contactMask == (PhysicsCategory.car | PhysicsCategory.obstacle) {
            let obstacleBody = bodyA.categoryBitMask == PhysicsCategory.obstacle ? bodyA : bodyB
            if let obstacleNode = obstacleBody.node as? ObstacleNode, !raceFinished {
                handleObstacleCollision(obstacleNode)
            }
        }

        if contactMask == (PhysicsCategory.car | PhysicsCategory.oncoming) {
            if !raceFinished {
                handleCrash()
            }
        }

        if contactMask == (PhysicsCategory.car | PhysicsCategory.finish) {
            if !raceFinished {
                finishRace()
            }
        }
    }

    private func handleObstacleCollision(_ obstacle: ObstacleNode) {
        // Enhancement 1: Reset combo on hit
        currentCombo = 0

        // Enhancement 4: Track hits
        gameState.obstaclesHit += 1

        switch obstacle.obstacleType {
        case .cone:
            ObstacleEffects.applyConeHit(to: &vehiclePhysics, scene: self, cameraNode: cameraNode2)
            // Enhancement 2: Cone explosion particles
            spawnConeParticles(at: obstacle.position)
        case .banana:
            ObstacleEffects.applyBananaHit(to: &vehiclePhysics)
            addSkidMarks()
            // Enhancement 2: Yellow skid streaks
            spawnBananaStreaks()
        }

        // Enhancement 2: Screen flash on any collision
        flashScreen(color: .red, alpha: 0.15, duration: 0.15)

        // Remove obstacle after hit
        obstacle.run(SKAction.sequence([
            SKAction.group([
                SKAction.fadeOut(withDuration: 0.2),
                SKAction.scale(to: 1.5, duration: 0.2)
            ]),
            SKAction.removeFromParent()
        ]))
    }

    // MARK: - Collision Particles (Enhancement 2)

    private func spawnConeParticles(at position: CGPoint) {
        let colors: [UIColor] = [.systemOrange, .white, .orange, .yellow]
        for _ in 0..<10 {
            let particle = SKShapeNode(rectOf: CGSize(width: CGFloat.random(in: 4...8), height: CGFloat.random(in: 3...6)))
            particle.fillColor = colors.randomElement()!
            particle.strokeColor = .clear
            particle.position = position
            particle.zPosition = ZPositions.effects + 2
            addChild(particle)

            let angle = CGFloat.random(in: 0...(2 * .pi))
            let distance = CGFloat.random(in: 30...80)
            let dx = cos(angle) * distance
            let dy = sin(angle) * distance

            particle.run(SKAction.sequence([
                SKAction.group([
                    SKAction.moveBy(x: dx, y: dy, duration: 0.4),
                    SKAction.rotate(byAngle: CGFloat.random(in: -3...3), duration: 0.4),
                    SKAction.fadeOut(withDuration: 0.35),
                    SKAction.scale(to: 0.3, duration: 0.4)
                ]),
                SKAction.removeFromParent()
            ]))
        }
    }

    private func spawnBananaStreaks() {
        for i in 0..<3 {
            let streak = SKShapeNode(rectOf: CGSize(width: 25, height: 2))
            streak.fillColor = UIColor.systemYellow.withAlphaComponent(0.5)
            streak.strokeColor = .clear
            streak.position = CGPoint(
                x: carNode.position.x - 10,
                y: carNode.position.y + CGFloat(i - 1) * 8
            )
            streak.zPosition = ZPositions.track + 1
            addChild(streak)

            streak.run(SKAction.sequence([
                SKAction.group([
                    SKAction.moveBy(x: -40, y: 0, duration: 1.0),
                    SKAction.fadeOut(withDuration: 1.0)
                ]),
                SKAction.removeFromParent()
            ]))
        }
    }

    private func addSkidMarks() {
        for i in 0..<5 {
            let mark = SKShapeNode(rectOf: CGSize(width: 12, height: 3))
            mark.fillColor = UIColor(white: 0.2, alpha: 0.4)
            mark.strokeColor = .clear
            mark.position = CGPoint(
                x: carNode.position.x - CGFloat(i) * 15,
                y: carNode.position.y + CGFloat.random(in: -5...5)
            )
            mark.zPosition = ZPositions.track + 1
            addChild(mark)
            mark.run(SKAction.sequence([
                SKAction.fadeOut(withDuration: 1.5),
                SKAction.removeFromParent()
            ]))
        }
    }

    // MARK: - Touch Handling

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard raceStarted, !raceFinished, !gameState.isPaused else { return }
        if let touch = touches.first {
            inputController.touchBegan(at: touch.location(in: self))
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard raceStarted, !raceFinished, !gameState.isPaused else { return }
        if let touch = touches.first {
            inputController.touchMoved(to: touch.location(in: self))
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        inputController.touchEnded()
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        inputController.touchEnded()
    }

    // MARK: - Pause

    func pauseGame() {
        gameState.isPaused = true
        // The race clock is dt-driven; it simply stops advancing because
        // update() early-returns while gameState.isPaused is true.
        // Do NOT set self.isPaused — SpriteView in SwiftUI doesn't reliably
        // unpause. Instead we gate on gameState.isPaused in update().
        // SKActions therefore KEEP RUNNING while paused, so the countdown
        // sequence must be cancelled explicitly; it restarts on resume.
        if gameState.isCountingDown {
            removeAction(forKey: "countdown")
            hudNode.hideCountdown()
        }
        AudioManager.shared.stopEngine()
    }

    func resumeGame() {
        gameState.isPaused = false
        // Reset lastUpdateTime so the first frame after unpause doesn't
        // have a huge delta from all the paused time.
        lastUpdateTime = 0
        // Ensure SKView/SpriteView hasn't auto-paused the scene or view
        self.isPaused = false
        self.view?.isPaused = false
        if gameState.isCountingDown {
            // Countdown was cancelled by pauseGame — restart it from 3.
            startCountdown()
        } else if raceStarted && !raceFinished {
            AudioManager.shared.startEngine()
        }
    }

    func cleanup() {
        AudioManager.shared.stopAll()
        removeAllActions()
        removeAllChildren()
    }
}
