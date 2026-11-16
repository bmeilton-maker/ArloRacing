import SpriteKit

class InputController {
    private(set) var touchActive: Bool = false
    private var currentTouchPosition: CGPoint?
    private var sceneSize: CGSize = .zero

    struct Input {
        var steer: CGFloat = 0
        /// 0.0 = no throttle, 1.0 = full throttle. Negative = braking.
        var throttle: CGFloat = 0
    }

    private(set) var currentInput = Input()

    var isActive: Bool { touchActive }

    func configure(sceneSize: CGSize) {
        self.sceneSize = sceneSize
    }

    func touchBegan(at position: CGPoint) {
        currentTouchPosition = position
        touchActive = true
        updateInput(position: position)
    }

    func touchMoved(to position: CGPoint) {
        let previous = currentTouchPosition
        currentTouchPosition = position
        updateInput(position: position, previousPosition: previous)
    }

    func touchEnded() {
        touchActive = false
        currentTouchPosition = nil
        currentInput = Input()
    }

    /// Steering is a per-touch-move delta. The scene must call this after
    /// consuming it each frame — otherwise a stationary finger leaves the
    /// last delta in place and the car drifts forever.
    func consumeSteer() {
        currentInput.steer = 0
    }

    func reset() {
        touchActive = false
        currentTouchPosition = nil
        currentInput = Input()
    }

    // MARK: - Private

    private func updateInput(position: CGPoint, previousPosition: CGPoint? = nil) {
        guard sceneSize.width > 0 else { return }

        // Throttle: based on absolute horizontal position on screen.
        // Left edge (0) = braking, car X position (~25%) = idle, right edge = full throttle.
        // Map so that touching at the car's X or left of it = 0 throttle (coast/brake),
        // and touching to the right scales linearly to 1.0 at the right edge.
        let carScreenX = sceneSize.width * GameConstants.carScreenXRatio
        let touchX = position.x

        if touchX <= carScreenX {
            // Touching at or behind the car = braking proportional to how far left
            currentInput.throttle = -((carScreenX - touchX) / carScreenX)
        } else {
            // Touching ahead of the car = accelerating
            let range = sceneSize.width - carScreenX
            currentInput.throttle = min((touchX - carScreenX) / range, 1.0)
        }

        // Steering: vertical delta between frames for smooth feel
        if let prev = previousPosition {
            currentInput.steer = position.y - prev.y
        } else {
            currentInput.steer = 0
        }
    }
}
