import SpriteKit

class HUDNode: SKNode {
    private var timerLabel: SKLabelNode!
    private var speedLabel: SKLabelNode!
    private var speedBarFill: SKSpriteNode!
    private var countdownLabel: SKLabelNode!
    private var countdownRing: SKShapeNode!
    private var comboLabel: SKLabelNode!
    private var comboShadowLabel: SKLabelNode!
    private var comboContainer: SKNode!
    private var lastComboValue: Int = 0

    /// Visual full-scale reference for the speed bar (roughly the fastest
    /// vehicle's top speed on the fastest track).
    private let speedBarMax: CGFloat = 520
    private let speedBarWidth: CGFloat = 96

    // Mini-map
    private var miniMapContainer: SKNode!
    private var miniMapBackground: SKShapeNode!
    private var miniMapTrack: SKShapeNode!
    private var miniMapCar: SKShapeNode!
    private var miniMapFinish: SKShapeNode!
    private var miniMapStartLabel: SKLabelNode!
    private var miniMapEndLabel: SKLabelNode!
    private let miniMapWidth: CGFloat = 180
    private let miniMapHeight: CGFloat = 32

    func setup(sceneSize: CGSize) {
        self.zPosition = ZPositions.hud

        // Rounded translucent panel behind timer + speed (top left)
        let panel = SKShapeNode(rect: CGRect(x: 12, y: sceneSize.height - 86, width: 150, height: 74), cornerRadius: 12)
        panel.fillColor = UIColor(white: 0.0, alpha: 0.5)
        panel.strokeColor = UIColor(white: 1.0, alpha: 0.18)
        panel.lineWidth = 1
        addChild(panel)

        // Timer (top left)
        timerLabel = SKLabelNode(fontNamed: "Menlo-Bold")
        timerLabel.fontSize = 24
        timerLabel.fontColor = .white
        timerLabel.horizontalAlignmentMode = .left
        timerLabel.verticalAlignmentMode = .top
        timerLabel.position = CGPoint(x: 24, y: sceneSize.height - 20)
        timerLabel.text = "0.000"
        addChild(timerLabel)

        // Speed readout + fill bar (below timer, inside the panel)
        speedLabel = SKLabelNode(fontNamed: "Menlo")
        speedLabel.fontSize = 14
        speedLabel.fontColor = UIColor(white: 1.0, alpha: 0.75)
        speedLabel.horizontalAlignmentMode = .left
        speedLabel.verticalAlignmentMode = .top
        speedLabel.position = CGPoint(x: 24, y: sceneSize.height - 52)
        speedLabel.text = "0 mph"
        addChild(speedLabel)

        let barBack = SKSpriteNode(color: UIColor(white: 1.0, alpha: 0.15), size: CGSize(width: speedBarWidth, height: 5))
        barBack.anchorPoint = CGPoint(x: 0, y: 0.5)
        barBack.position = CGPoint(x: 24, y: sceneSize.height - 76)
        addChild(barBack)

        speedBarFill = SKSpriteNode(color: .systemOrange, size: CGSize(width: speedBarWidth, height: 5))
        speedBarFill.anchorPoint = CGPoint(x: 0, y: 0.5)
        speedBarFill.position = barBack.position
        speedBarFill.xScale = 0
        addChild(speedBarFill)

        // Mini-map (bottom-right corner)
        setupMiniMap(sceneSize: sceneSize)

        // Combo counter (top center) with a soft drop shadow so it reads
        // over any background. Animations run on the container so both
        // labels move together.
        comboContainer = SKNode()
        comboContainer.position = CGPoint(x: sceneSize.width / 2, y: sceneSize.height - 20)
        comboContainer.alpha = 0
        addChild(comboContainer)

        comboShadowLabel = SKLabelNode(fontNamed: "Menlo-Bold")
        comboShadowLabel.fontSize = 20
        comboShadowLabel.fontColor = UIColor(white: 0, alpha: 0.6)
        comboShadowLabel.horizontalAlignmentMode = .center
        comboShadowLabel.verticalAlignmentMode = .top
        comboShadowLabel.position = CGPoint(x: 1.5, y: -1.5)
        comboContainer.addChild(comboShadowLabel)

        comboLabel = SKLabelNode(fontNamed: "Menlo-Bold")
        comboLabel.fontSize = 20
        comboLabel.fontColor = .systemOrange
        comboLabel.horizontalAlignmentMode = .center
        comboLabel.verticalAlignmentMode = .top
        comboContainer.addChild(comboLabel)

        // Countdown label (center) + expanding pulse ring
        countdownRing = SKShapeNode(circleOfRadius: 56)
        countdownRing.fillColor = .clear
        countdownRing.lineWidth = 4
        countdownRing.position = CGPoint(x: sceneSize.width / 2, y: sceneSize.height / 2)
        countdownRing.isHidden = true
        addChild(countdownRing)

        countdownLabel = SKLabelNode(fontNamed: "Menlo-Bold")
        countdownLabel.fontSize = 72
        countdownLabel.fontColor = .white
        countdownLabel.horizontalAlignmentMode = .center
        countdownLabel.verticalAlignmentMode = .center
        countdownLabel.position = CGPoint(x: sceneSize.width / 2, y: sceneSize.height / 2)
        countdownLabel.isHidden = true
        addChild(countdownLabel)
    }

    // MARK: - Mini-Map

    private func setupMiniMap(sceneSize: CGSize) {
        miniMapContainer = SKNode()
        let mapX = sceneSize.width - miniMapWidth - 24
        let mapY: CGFloat = 24
        miniMapContainer.position = CGPoint(x: mapX, y: mapY)
        addChild(miniMapContainer)

        // Rounded background panel
        let panelRect = CGRect(x: -8, y: -10, width: miniMapWidth + 16, height: miniMapHeight + 28)
        miniMapBackground = SKShapeNode(rect: panelRect, cornerRadius: 8)
        miniMapBackground.fillColor = UIColor(white: 0.0, alpha: 0.55)
        miniMapBackground.strokeColor = UIColor(white: 1.0, alpha: 0.2)
        miniMapBackground.lineWidth = 1
        miniMapContainer.addChild(miniMapBackground)

        // Track strip (the road line)
        miniMapTrack = SKShapeNode(rectOf: CGSize(width: miniMapWidth, height: 6), cornerRadius: 3)
        miniMapTrack.fillColor = UIColor(white: 0.4, alpha: 1.0)
        miniMapTrack.strokeColor = .clear
        miniMapTrack.position = CGPoint(x: miniMapWidth / 2, y: miniMapHeight / 2)
        miniMapContainer.addChild(miniMapTrack)

        // Start marker
        let startLine = SKShapeNode(rectOf: CGSize(width: 2, height: 14))
        startLine.fillColor = UIColor(white: 1.0, alpha: 0.5)
        startLine.strokeColor = .clear
        startLine.position = CGPoint(x: 0, y: miniMapHeight / 2)
        miniMapContainer.addChild(startLine)

        // Finish marker (checkered flag icon)
        miniMapFinish = SKShapeNode(rectOf: CGSize(width: 3, height: 14))
        miniMapFinish.fillColor = .white
        miniMapFinish.strokeColor = .clear
        miniMapFinish.position = CGPoint(x: miniMapWidth, y: miniMapHeight / 2)
        miniMapContainer.addChild(miniMapFinish)

        // "START" label
        miniMapStartLabel = SKLabelNode(fontNamed: "Menlo")
        miniMapStartLabel.fontSize = 8
        miniMapStartLabel.fontColor = UIColor(white: 1.0, alpha: 0.5)
        miniMapStartLabel.horizontalAlignmentMode = .left
        miniMapStartLabel.verticalAlignmentMode = .bottom
        miniMapStartLabel.position = CGPoint(x: 0, y: miniMapHeight / 2 + 10)
        miniMapStartLabel.text = "START"
        miniMapContainer.addChild(miniMapStartLabel)

        // "FINISH" label
        miniMapEndLabel = SKLabelNode(fontNamed: "Menlo")
        miniMapEndLabel.fontSize = 8
        miniMapEndLabel.fontColor = UIColor(white: 1.0, alpha: 0.5)
        miniMapEndLabel.horizontalAlignmentMode = .right
        miniMapEndLabel.verticalAlignmentMode = .bottom
        miniMapEndLabel.position = CGPoint(x: miniMapWidth, y: miniMapHeight / 2 + 10)
        miniMapEndLabel.text = "FINISH"
        miniMapContainer.addChild(miniMapEndLabel)

        // Car dot (bright, larger)
        miniMapCar = SKShapeNode(circleOfRadius: 5)
        miniMapCar.fillColor = .systemOrange
        miniMapCar.strokeColor = .white
        miniMapCar.lineWidth = 1.5
        miniMapCar.position = CGPoint(x: 0, y: miniMapHeight / 2)
        miniMapCar.glowWidth = 2
        miniMapContainer.addChild(miniMapCar)

        // Gentle pulse so the player's eye finds their progress at a glance
        let pulse = SKAction.sequence([
            SKAction.scale(to: 1.25, duration: 0.7),
            SKAction.scale(to: 1.0, duration: 0.7)
        ])
        miniMapCar.run(SKAction.repeatForever(pulse))
    }

    func updateTimer(_ time: TimeInterval) {
        timerLabel.text = time.raceTimeString
    }

    func updateSpeed(_ speed: CGFloat) {
        let displaySpeed = Int(speed * 0.5) // scale to realistic mph range
        speedLabel.text = "\(displaySpeed) mph"

        let ratio = min(speed / speedBarMax, 1.0)
        speedBarFill.xScale = ratio
        speedBarFill.color = ratio > 0.85 ? .systemRed : (ratio > 0.6 ? .systemYellow : .systemOrange)
    }

    func updateProgress(_ ratio: CGFloat) {
        let clampedRatio = min(max(ratio, 0), 1)
        let xPos = clampedRatio * miniMapWidth
        miniMapCar.position.x = xPos
    }

    func updateCombo(_ combo: Int) {
        if combo > 1 {
            let text = "x\(combo) COMBO"
            let fontSize = min(20 + CGFloat(combo) * 2, 32)
            comboLabel.text = text
            comboLabel.fontSize = fontSize
            comboLabel.fontColor = combo > 5 ? .yellow : .systemOrange
            comboShadowLabel.text = text
            comboShadowLabel.fontSize = fontSize

            if combo > lastComboValue {
                // Pulse animation on increment
                comboContainer.removeAction(forKey: "comboPulse")
                comboContainer.alpha = 1.0
                comboContainer.setScale(1.3)
                comboContainer.run(SKAction.scale(to: 1.0, duration: 0.15), withKey: "comboPulse")
            }
        } else {
            if lastComboValue > 1 {
                // Fade out when combo breaks
                comboContainer.run(SKAction.fadeOut(withDuration: 0.3))
            }
        }
        lastComboValue = combo
    }

    func showCountdown(_ text: String) {
        let isGo = text == "GO!"
        let accent: UIColor = isGo ? .systemGreen : .white

        countdownLabel.isHidden = false
        countdownLabel.text = text
        countdownLabel.fontColor = accent
        countdownLabel.setScale(0.5)
        countdownLabel.alpha = 1.0

        let scaleUp = SKAction.scale(to: isGo ? 1.35 : 1.2, duration: 0.3)
        let scaleDown = SKAction.scale(to: 1.0, duration: 0.1)
        let fadeOut = SKAction.sequence([
            SKAction.wait(forDuration: 0.5),
            SKAction.fadeOut(withDuration: 0.3)
        ])
        countdownLabel.run(SKAction.group([
            SKAction.sequence([scaleUp, scaleDown]),
            fadeOut
        ]))

        // Expanding ring pulse behind the number
        countdownRing.removeAllActions()
        countdownRing.isHidden = false
        countdownRing.strokeColor = accent.withAlphaComponent(0.8)
        countdownRing.setScale(0.5)
        countdownRing.alpha = 1.0
        countdownRing.run(SKAction.group([
            SKAction.scale(to: isGo ? 2.0 : 1.5, duration: 0.55),
            SKAction.fadeOut(withDuration: 0.55)
        ]))
    }

    func hideCountdown() {
        countdownLabel.isHidden = true
        countdownRing.isHidden = true
    }
}
