import SpriteKit

class HUDNode: SKNode {
    private var timerLabel: SKLabelNode!
    private var speedLabel: SKLabelNode!
    private var countdownLabel: SKLabelNode!
    private var comboLabel: SKLabelNode!
    private var lastComboValue: Int = 0

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

        // Timer (top left)
        timerLabel = SKLabelNode(fontNamed: "Menlo-Bold")
        timerLabel.fontSize = 24
        timerLabel.fontColor = .white
        timerLabel.horizontalAlignmentMode = .left
        timerLabel.verticalAlignmentMode = .top
        timerLabel.position = CGPoint(x: 20, y: sceneSize.height - 20)
        timerLabel.text = "0.000"
        addChild(timerLabel)

        // Speed indicator (top left, below timer)
        speedLabel = SKLabelNode(fontNamed: "Menlo")
        speedLabel.fontSize = 16
        speedLabel.fontColor = UIColor(white: 1.0, alpha: 0.7)
        speedLabel.horizontalAlignmentMode = .left
        speedLabel.verticalAlignmentMode = .top
        speedLabel.position = CGPoint(x: 20, y: sceneSize.height - 50)
        speedLabel.text = "0 mph"
        addChild(speedLabel)

        // Mini-map (bottom-right corner)
        setupMiniMap(sceneSize: sceneSize)

        // Combo counter (top center-right)
        comboLabel = SKLabelNode(fontNamed: "Menlo-Bold")
        comboLabel.fontSize = 20
        comboLabel.fontColor = .systemOrange
        comboLabel.horizontalAlignmentMode = .center
        comboLabel.verticalAlignmentMode = .top
        comboLabel.position = CGPoint(x: sceneSize.width / 2, y: sceneSize.height - 20)
        comboLabel.alpha = 0
        addChild(comboLabel)

        // Countdown label (center)
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
    }

    func updateTimer(_ time: TimeInterval) {
        timerLabel.text = time.raceTimeString
    }

    func updateSpeed(_ speed: CGFloat, maxSpeed: CGFloat) {
        let displaySpeed = Int(speed * 0.5) // scale to realistic mph range
        speedLabel.text = "\(displaySpeed) mph"
    }

    func updateProgress(_ ratio: CGFloat) {
        let clampedRatio = min(max(ratio, 0), 1)
        let xPos = clampedRatio * miniMapWidth
        miniMapCar.position.x = xPos
    }

    func updateCombo(_ combo: Int) {
        if combo > 1 {
            comboLabel.text = "x\(combo) COMBO"
            comboLabel.fontSize = min(20 + CGFloat(combo) * 2, 32)
            comboLabel.fontColor = combo > 5 ? .yellow : .systemOrange

            if combo > lastComboValue {
                // Pulse animation on increment
                comboLabel.removeAction(forKey: "comboPulse")
                comboLabel.alpha = 1.0
                comboLabel.setScale(1.3)
                comboLabel.run(SKAction.scale(to: 1.0, duration: 0.15), withKey: "comboPulse")
            }
        } else {
            if lastComboValue > 1 {
                // Fade out when combo breaks
                comboLabel.run(SKAction.fadeOut(withDuration: 0.3))
            }
        }
        lastComboValue = combo
    }

    func showCountdown(_ text: String) {
        countdownLabel.isHidden = false
        countdownLabel.text = text
        countdownLabel.setScale(0.5)
        countdownLabel.alpha = 1.0

        let scaleUp = SKAction.scale(to: 1.2, duration: 0.3)
        let scaleDown = SKAction.scale(to: 1.0, duration: 0.1)
        let fadeOut = SKAction.sequence([
            SKAction.wait(forDuration: 0.5),
            SKAction.fadeOut(withDuration: 0.3)
        ])
        countdownLabel.run(SKAction.group([
            SKAction.sequence([scaleUp, scaleDown]),
            fadeOut
        ]))
    }

    func hideCountdown() {
        countdownLabel.isHidden = true
    }
}
