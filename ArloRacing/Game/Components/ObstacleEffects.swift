import SpriteKit

class ObstacleEffects {
    static func applyConeHit(to physics: inout VehiclePhysics, scene: SKScene, cameraNode: SKCameraNode?) {
        physics.currentSpeed *= 0.5
        if let cam = cameraNode {
            cam.run(SKAction.shake(duration: 0.2, intensity: 3.0))
        }
        AudioManager.shared.play(.coneHit)
    }

    static func applyBananaHit(to physics: inout VehiclePhysics) {
        physics.isSlipping = true
        physics.slipTimer = GameConstants.slipDuration
        physics.gripFactor = physics.baseGripFactor * 0.3
        AudioManager.shared.play(.skid)
    }

    static func applyHeavyCollision(to physics: inout VehiclePhysics, carNode: SKSpriteNode) {
        physics.currentSpeed = 10
        physics.isRecovering = true
        physics.recoveryTimer = GameConstants.recoveryDuration

        let spin = SKAction.rotate(byAngle: .pi * 2, duration: 0.5)
        carNode.run(spin)
    }
}
