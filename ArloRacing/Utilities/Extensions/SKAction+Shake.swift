import SpriteKit

extension SKAction {
    static func shake(duration: TimeInterval, intensity: CGFloat) -> SKAction {
        let shakeCount = Int(duration / 0.04)
        var actions: [SKAction] = []

        for _ in 0..<shakeCount {
            let dx = CGFloat.random(in: -intensity...intensity)
            let dy = CGFloat.random(in: -intensity...intensity)
            actions.append(SKAction.moveBy(x: dx, y: dy, duration: 0.02))
            actions.append(SKAction.moveBy(x: -dx, y: -dy, duration: 0.02))
        }

        return SKAction.sequence(actions)
    }
}
