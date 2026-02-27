import SpriteKit

struct PhysicsCategory {
    static let none:       UInt32 = 0
    static let car:        UInt32 = 0b00001
    static let obstacle:   UInt32 = 0b00010
    static let bounds:     UInt32 = 0b00100
    static let finish:     UInt32 = 0b01000
    static let oncoming:   UInt32 = 0b10000
}

class PhysicsController {
    static func setupPhysicsWorld(_ scene: SKScene) {
        scene.physicsWorld.gravity = .zero
    }

    static func setupCarPhysics(_ carNode: SKSpriteNode) {
        let body = SKPhysicsBody(rectangleOf: carNode.size)
        body.isDynamic = true
        body.categoryBitMask = PhysicsCategory.car
        body.contactTestBitMask = PhysicsCategory.obstacle | PhysicsCategory.finish | PhysicsCategory.oncoming
        body.collisionBitMask = PhysicsCategory.bounds
        body.affectedByGravity = false
        body.allowsRotation = false
        carNode.physicsBody = body
    }

    static func setupOncomingCarPhysics(_ node: SKSpriteNode) {
        let body = SKPhysicsBody(rectangleOf: node.size)
        body.isDynamic = true
        body.affectedByGravity = false
        body.allowsRotation = false
        body.velocity = .zero
        body.linearDamping = 0
        body.categoryBitMask = PhysicsCategory.oncoming
        body.contactTestBitMask = PhysicsCategory.car
        body.collisionBitMask = PhysicsCategory.none
        node.physicsBody = body
    }

    static func setupObstaclePhysics(_ obstacleNode: SKSpriteNode) {
        let body = SKPhysicsBody(rectangleOf: obstacleNode.size)
        body.isDynamic = true
        body.affectedByGravity = false
        body.allowsRotation = false
        body.velocity = .zero
        body.linearDamping = 0
        body.categoryBitMask = PhysicsCategory.obstacle
        body.contactTestBitMask = PhysicsCategory.car
        body.collisionBitMask = PhysicsCategory.none
        obstacleNode.physicsBody = body
    }

    static func setupFinishLinePhysics(_ finishNode: SKSpriteNode) {
        let body = SKPhysicsBody(rectangleOf: finishNode.size)
        body.isDynamic = true
        body.affectedByGravity = false
        body.allowsRotation = false
        body.velocity = .zero
        body.linearDamping = 0
        body.categoryBitMask = PhysicsCategory.finish
        body.contactTestBitMask = PhysicsCategory.car
        body.collisionBitMask = PhysicsCategory.none
        finishNode.physicsBody = body
    }

    static func setupTrackBounds(_ scene: SKScene, trackHeight: CGFloat, yOffset: CGFloat) {
        let topWall = SKNode()
        topWall.position = CGPoint(x: scene.size.width / 2, y: yOffset + trackHeight)
        topWall.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: scene.size.width * 3, height: 2))
        topWall.physicsBody?.isDynamic = false
        topWall.physicsBody?.categoryBitMask = PhysicsCategory.bounds
        scene.addChild(topWall)

        let bottomWall = SKNode()
        bottomWall.position = CGPoint(x: scene.size.width / 2, y: yOffset)
        bottomWall.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: scene.size.width * 3, height: 2))
        bottomWall.physicsBody?.isDynamic = false
        bottomWall.physicsBody?.categoryBitMask = PhysicsCategory.bounds
        scene.addChild(bottomWall)
    }
}
