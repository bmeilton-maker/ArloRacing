import XCTest
@testable import ArloRacing

final class ArloRacingTests: XCTestCase {

    // MARK: - Vehicle Tests

    func testAllVehiclesExist() {
        XCTAssertEqual(allVehicles.count, 4)
    }

    func testVehicleIds() {
        let ids = allVehicles.map { $0.id }
        XCTAssertTrue(ids.contains("sports"))
        XCTAssertTrue(ids.contains("pickup"))
        XCTAssertTrue(ids.contains("monster"))
        XCTAssertTrue(ids.contains("motorcycle"))
    }

    func testMotorcycleFastest() {
        let motorcycle = allVehicles.first { $0.id == "motorcycle" }!
        let maxSpeedOfOthers = allVehicles.filter { $0.id != "motorcycle" }.map { $0.maxSpeed }.max()!
        XCTAssertGreaterThan(motorcycle.maxSpeed, maxSpeedOfOthers)
    }

    func testMonsterTruckBestGrip() {
        let monster = allVehicles.first { $0.id == "monster" }!
        let maxGripOfOthers = allVehicles.filter { $0.id != "monster" }.map { $0.grip }.max()!
        XCTAssertGreaterThanOrEqual(monster.grip, maxGripOfOthers)
    }

    // MARK: - Track Tests

    func testAllTracksExist() {
        XCTAssertEqual(allTracks.count, 5)
    }

    func testTrackIdsUnique() {
        let ids = Set(allTracks.map { $0.id })
        XCTAssertEqual(ids.count, 5)
    }

    func testTrackSeedsUnique() {
        let seeds = Set(allTracks.map { $0.seed })
        XCTAssertEqual(seeds.count, 5)
    }

    func testAllThemesCovered() {
        let themes = Set(allTracks.map { $0.theme })
        XCTAssertEqual(themes.count, 5)
        XCTAssertTrue(themes.contains(.desert))
        XCTAssertTrue(themes.contains(.forest))
        XCTAssertTrue(themes.contains(.urban))
        XCTAssertTrue(themes.contains(.night))
        XCTAssertTrue(themes.contains(.arctic))
    }

    func testTrackLengthsPositive() {
        for track in allTracks {
            XCTAssertGreaterThan(track.length, 0, "Track \(track.name) should have positive length")
        }
    }

    // MARK: - VehiclePhysics Tests

    func testPhysicsInitialization() {
        let vehicle = allVehicles[0]
        let physics = VehiclePhysics(vehicle: vehicle, trackModifier: 1.0)
        XCTAssertEqual(physics.currentSpeed, 0)
        XCTAssertEqual(physics.maxSpeed, vehicle.maxSpeed)
        XCTAssertFalse(physics.isSlipping)
        XCTAssertFalse(physics.isRecovering)
    }

    func testAcceleration() {
        let vehicle = allVehicles[0]
        var physics = VehiclePhysics(vehicle: vehicle, trackModifier: 1.0)
        let initialSpeed = physics.currentSpeed
        physics.update(deltaTime: 0.1, throttle: 1.0, fingerDown: true)
        XCTAssertGreaterThan(physics.currentSpeed, initialSpeed)
    }

    func testBraking() {
        let vehicle = allVehicles[0]
        var physics = VehiclePhysics(vehicle: vehicle, trackModifier: 1.0)
        // First accelerate
        for _ in 0..<20 {
            physics.update(deltaTime: 0.1, throttle: 1.0, fingerDown: true)
        }
        let speedBeforeBrake = physics.currentSpeed
        XCTAssertGreaterThan(speedBeforeBrake, 0)
        // Now brake
        physics.update(deltaTime: 0.1, throttle: -1.0, fingerDown: true)
        XCTAssertLessThan(physics.currentSpeed, speedBeforeBrake)
    }

    func testMaxSpeedCap() {
        let vehicle = allVehicles[0]
        var physics = VehiclePhysics(vehicle: vehicle, trackModifier: 1.0)
        for _ in 0..<1000 {
            physics.update(deltaTime: 0.1, throttle: 1.0, fingerDown: true)
        }
        XCTAssertLessThanOrEqual(physics.currentSpeed, physics.maxSpeed)
    }

    func testSpeedNeverNegative() {
        let vehicle = allVehicles[0]
        var physics = VehiclePhysics(vehicle: vehicle, trackModifier: 1.0)
        for _ in 0..<100 {
            physics.update(deltaTime: 0.1, throttle: -1.0, fingerDown: true)
        }
        XCTAssertGreaterThanOrEqual(physics.currentSpeed, 0)
    }

    func testTrackModifier() {
        let vehicle = allVehicles[0]
        let physics1 = VehiclePhysics(vehicle: vehicle, trackModifier: 1.0)
        let physics2 = VehiclePhysics(vehicle: vehicle, trackModifier: 0.5)
        XCTAssertEqual(physics2.maxSpeed, physics1.maxSpeed * 0.5)
    }

    func testSlipState() {
        let vehicle = allVehicles[0]
        var physics = VehiclePhysics(vehicle: vehicle, trackModifier: 1.0)
        physics.isSlipping = true
        physics.slipTimer = 1.5
        physics.gripFactor = physics.baseGripFactor * 0.3

        XCTAssertTrue(physics.isSlipping)

        // Simulate time passing
        for _ in 0..<20 {
            physics.update(deltaTime: 0.1, throttle: 1.0, fingerDown: true)
        }

        XCTAssertFalse(physics.isSlipping)
        XCTAssertEqual(physics.gripFactor, physics.baseGripFactor)
    }

    func testRecoveryState() {
        let vehicle = allVehicles[0]
        var physics = VehiclePhysics(vehicle: vehicle, trackModifier: 1.0)
        // First get some speed
        for _ in 0..<10 {
            physics.update(deltaTime: 0.1, throttle: 1.0, fingerDown: true)
        }
        let speedBefore = physics.currentSpeed

        physics.isRecovering = true
        physics.recoveryTimer = 1.0

        // During recovery, speed should not change due to acceleration
        physics.update(deltaTime: 0.1, throttle: 1.0, fingerDown: true)
        XCTAssertEqual(physics.currentSpeed, speedBefore) // No change during recovery
    }

    func testSpeedRatio() {
        let vehicle = allVehicles[0]
        var physics = VehiclePhysics(vehicle: vehicle, trackModifier: 1.0)
        XCTAssertEqual(physics.speedRatio, 0)

        for _ in 0..<1000 {
            physics.update(deltaTime: 0.1, throttle: 1.0, fingerDown: true)
        }
        XCTAssertEqual(physics.speedRatio, 1.0, accuracy: 0.01)
    }

    // MARK: - TimingSystem Tests

    func testTimingStart() {
        let timing = TimingSystem()
        XCTAssertEqual(timing.elapsedTime, 0)
        timing.start()
        XCTAssertTrue(timing.isRunning)
    }

    func testTimingPauseResume() {
        let timing = TimingSystem()
        timing.start()

        Thread.sleep(forTimeInterval: 0.05)
        timing.pause()
        let pausedTime = timing.elapsedTime

        Thread.sleep(forTimeInterval: 0.05)
        let stillPausedTime = timing.elapsedTime
        // Time should not advance much while paused
        XCTAssertEqual(pausedTime, stillPausedTime, accuracy: 0.01)

        timing.resume()
        XCTAssertTrue(timing.isRunning)
    }

    func testTimingStop() {
        let timing = TimingSystem()
        timing.start()
        Thread.sleep(forTimeInterval: 0.05)
        let finalTime = timing.stop()
        XCTAssertGreaterThan(finalTime, 0)
        XCTAssertFalse(timing.isRunning)
    }

    func testTimingReset() {
        let timing = TimingSystem()
        timing.start()
        Thread.sleep(forTimeInterval: 0.05)
        _ = timing.stop()
        timing.reset()
        XCTAssertEqual(timing.elapsedTime, 0)
        XCTAssertFalse(timing.isRunning)
    }

    // MARK: - InputController Tests

    func testInputInitialState() {
        let input = InputController()
        XCTAssertFalse(input.isActive)
        XCTAssertEqual(input.currentInput.steer, 0)
        XCTAssertEqual(input.currentInput.throttle, 0)
    }

    func testTouchBegan() {
        let input = InputController()
        input.configure(sceneSize: CGSize(width: 800, height: 400))
        input.touchBegan(at: CGPoint(x: 600, y: 200))
        XCTAssertTrue(input.isActive)
        // Touching right of car (25% = 200) should produce positive throttle
        XCTAssertGreaterThan(input.currentInput.throttle, 0)
    }

    func testTouchMovedSteering() {
        let input = InputController()
        input.configure(sceneSize: CGSize(width: 800, height: 400))
        input.touchBegan(at: CGPoint(x: 600, y: 200))
        input.touchMoved(to: CGPoint(x: 600, y: 220))
        XCTAssertEqual(input.currentInput.steer, 20) // deltaY = 220 - 200
    }

    func testThrottleProportionalToPosition() {
        let input = InputController()
        input.configure(sceneSize: CGSize(width: 800, height: 400))
        // Touch at right edge = full throttle
        input.touchBegan(at: CGPoint(x: 800, y: 200))
        XCTAssertEqual(input.currentInput.throttle, 1.0, accuracy: 0.01)
    }

    func testBrakingBehindCar() {
        let input = InputController()
        input.configure(sceneSize: CGSize(width: 800, height: 400))
        // Touch at left edge (behind car at x=200) = braking
        input.touchBegan(at: CGPoint(x: 0, y: 200))
        XCTAssertLessThan(input.currentInput.throttle, 0)
    }

    func testTouchEnded() {
        let input = InputController()
        input.configure(sceneSize: CGSize(width: 800, height: 400))
        input.touchBegan(at: CGPoint(x: 600, y: 200))
        input.touchEnded()
        XCTAssertFalse(input.isActive)
    }

    func testInputReset() {
        let input = InputController()
        input.configure(sceneSize: CGSize(width: 800, height: 400))
        input.touchBegan(at: CGPoint(x: 600, y: 200))
        input.reset()
        XCTAssertFalse(input.isActive)
        XCTAssertEqual(input.currentInput.steer, 0)
        XCTAssertEqual(input.currentInput.throttle, 0)
    }

    // MARK: - TrackGenerator Tests

    func testDeterministicGeneration() {
        let gen1 = TrackGenerator(seed: 12345)
        let gen2 = TrackGenerator(seed: 12345)

        let obs1 = gen1.generateObstacles(density: 0.5, trackLength: 5000, laneCount: 5)
        let obs2 = gen2.generateObstacles(density: 0.5, trackLength: 5000, laneCount: 5)

        XCTAssertEqual(obs1.count, obs2.count)
        for i in 0..<obs1.count {
            XCTAssertEqual(obs1[i].x, obs2[i].x)
            XCTAssertEqual(obs1[i].lane, obs2[i].lane)
        }
    }

    func testDifferentSeedsDifferentOutput() {
        let gen1 = TrackGenerator(seed: 12345)
        let gen2 = TrackGenerator(seed: 67890)

        let obs1 = gen1.generateObstacles(density: 0.5, trackLength: 5000, laneCount: 5)
        let obs2 = gen2.generateObstacles(density: 0.5, trackLength: 5000, laneCount: 5)

        // Very unlikely to be identical with different seeds
        let countDiffers = obs1.count != obs2.count
        var positionDiffers = false
        if obs1.count == obs2.count && obs1.count > 0 {
            for i in 0..<obs1.count {
                if obs1[i].lane != obs2[i].lane {
                    positionDiffers = true
                    break
                }
            }
        }
        XCTAssertTrue(countDiffers || positionDiffers)
    }

    func testObstaclesStartAfterOffset() {
        let gen = TrackGenerator(seed: 12345)
        let obstacles = gen.generateObstacles(density: 1.0, trackLength: 5000, laneCount: 5)
        for obs in obstacles {
            XCTAssertGreaterThanOrEqual(obs.x, GameConstants.obstacleStartOffset)
        }
    }

    func testObstacleLanesInRange() {
        let gen = TrackGenerator(seed: 12345)
        let laneCount = 5
        let obstacles = gen.generateObstacles(density: 0.8, trackLength: 10000, laneCount: laneCount)
        for obs in obstacles {
            XCTAssertGreaterThanOrEqual(obs.lane, 0)
            XCTAssertLessThan(obs.lane, laneCount)
        }
    }

    func testZeroDensityNoObstacles() {
        let gen = TrackGenerator(seed: 12345)
        let obstacles = gen.generateObstacles(density: 0.0, trackLength: 5000, laneCount: 5)
        XCTAssertEqual(obstacles.count, 0)
    }

    // MARK: - GameState Tests

    func testGameStateReset() {
        let state = GameState()
        state.lastRaceTime = 42.5
        state.isRaceComplete = true
        state.isCrashed = true
        state.isPaused = true
        state.isCountingDown = true
        state.shouldRetry = true
        state.shouldQuitToMenu = true
        state.dodgeCount = 5
        state.maxCombo = 3
        state.obstaclesHit = 2
        state.topSpeedReached = 300

        state.reset()

        XCTAssertNil(state.lastRaceTime)
        XCTAssertFalse(state.isRaceComplete)
        XCTAssertFalse(state.isCrashed)
        XCTAssertFalse(state.isPaused)
        XCTAssertFalse(state.isCountingDown)
        XCTAssertFalse(state.shouldRetry)
        XCTAssertFalse(state.shouldQuitToMenu)
        XCTAssertEqual(state.dodgeCount, 0)
        XCTAssertEqual(state.maxCombo, 0)
        XCTAssertEqual(state.obstaclesHit, 0)
        XCTAssertEqual(state.topSpeedReached, 0)
    }

    func testGameStateDefaults() {
        let state = GameState()
        XCTAssertNil(state.selectedTrack)
        XCTAssertNil(state.selectedVehicle)
        XCTAssertNil(state.lastRaceTime)
        XCTAssertFalse(state.isRaceComplete)
        XCTAssertFalse(state.isPaused)
        XCTAssertEqual(state.dodgeCount, 0)
        XCTAssertEqual(state.maxCombo, 0)
        XCTAssertEqual(state.obstaclesHit, 0)
        XCTAssertEqual(state.topSpeedReached, 0)
    }

    // MARK: - Constants Tests

    func testGameConstants() {
        XCTAssertEqual(GameConstants.carScreenXRatio, 0.25)
        XCTAssertEqual(GameConstants.laneCount, 5)
        XCTAssertEqual(GameConstants.leaderboardMaxEntries, 10)
        XCTAssertEqual(GameConstants.countdownDuration, 3.0)
        XCTAssertEqual(GameConstants.slipDuration, 1.5)
        XCTAssertEqual(GameConstants.recoveryDuration, 1.0)
        XCTAssertEqual(GameConstants.dodgeDistanceThreshold, 60)
        XCTAssertEqual(GameConstants.dustSpawnInterval, 0.15)
    }

    // MARK: - TimeInterval Extension Tests

    func testRaceTimeStringFormatting() {
        let time1: TimeInterval = 45.123
        XCTAssertEqual(time1.raceTimeString, "45.123")

        let time2: TimeInterval = 65.456
        XCTAssertEqual(time2.raceTimeString, "1:05.456")
    }

    func testMillisToRaceTime() {
        XCTAssertEqual(45123.millisToRaceTime, "45.123")
        XCTAssertEqual(65456.millisToRaceTime, "1:05.456")
    }
}
