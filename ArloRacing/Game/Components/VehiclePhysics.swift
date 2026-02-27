import Foundation

struct VehiclePhysics {
    var currentSpeed: CGFloat = 0
    var maxSpeed: CGFloat
    var accelerationRate: CGFloat
    var brakeRate: CGFloat
    var gripFactor: CGFloat
    var baseGripFactor: CGFloat

    var isSlipping: Bool = false
    var slipTimer: TimeInterval = 0
    var isRecovering: Bool = false
    var recoveryTimer: TimeInterval = 0

    init(vehicle: Vehicle, trackModifier: CGFloat) {
        self.maxSpeed = vehicle.maxSpeed * trackModifier
        self.accelerationRate = vehicle.acceleration
        self.brakeRate = vehicle.braking
        self.gripFactor = vehicle.grip
        self.baseGripFactor = vehicle.grip
    }

    /// throttle: -1.0 (full brake) to 1.0 (full throttle). 0 = coasting.
    /// fingerDown: whether the player is touching the screen at all.
    mutating func update(deltaTime: TimeInterval, throttle: CGFloat, fingerDown: Bool) {
        let dt = CGFloat(deltaTime)

        // Update slip timer
        if isSlipping {
            slipTimer -= deltaTime
            if slipTimer <= 0 {
                isSlipping = false
                gripFactor = baseGripFactor
            }
        }

        // Update recovery timer
        if isRecovering {
            recoveryTimer -= deltaTime
            if recoveryTimer <= 0 {
                isRecovering = false
            }
            return // No acceleration during recovery
        }

        if !fingerDown {
            // Finger lifted = full brake to stop
            currentSpeed = max(currentSpeed - brakeRate * dt, 0)
        } else if throttle > 0 {
            // Accelerate proportional to throttle amount
            let targetSpeed = maxSpeed * throttle
            if currentSpeed < targetSpeed {
                currentSpeed = min(currentSpeed + accelerationRate * throttle * dt, targetSpeed)
            } else {
                // Above target (e.g. moved finger left) - coast down gently
                currentSpeed = max(currentSpeed - (brakeRate * 0.2) * dt, targetSpeed)
            }
        } else if throttle < 0 {
            // Active braking (finger behind car)
            currentSpeed = max(currentSpeed - brakeRate * abs(throttle) * dt, 0)
        } else {
            // Finger on screen at car position = gentle coast
            currentSpeed = max(currentSpeed - (brakeRate * 0.15) * dt, 0)
        }
    }

    var speedRatio: CGFloat {
        maxSpeed > 0 ? currentSpeed / maxSpeed : 0
    }
}
