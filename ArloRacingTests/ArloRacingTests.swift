import XCTest
import SwiftData
@testable import ArloRacing

final class ArloRacingTests: XCTestCase {

    // MARK: - LeaderboardManager Tests

    /// Returns the container (not just the context): the context must not
    /// outlive its container, so each test holds the container for its
    /// full duration.
    @MainActor
    private func makeInMemoryContainer() throws -> ModelContainer {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        return try ModelContainer(for: LeaderboardEntry.self, configurations: config)
    }

    @MainActor
    func testIsTopScoreWhenBoardNotFull() throws {
        let container = try makeInMemoryContainer()
        let context = container.mainContext
        for i in 0..<5 {
            LeaderboardManager.addEntry(
                LeaderboardEntry(trackId: 1, playerName: "P\(i)", timeMillis: 10_000 + i * 1000, vehicleId: "sports"),
                context: context
            )
        }
        // Board has 5 of 10 slots — even a slow time qualifies
        XCTAssertTrue(LeaderboardManager.isTopScore(trackId: 1, timeMillis: 99_999, context: context))
    }

    @MainActor
    func testIsTopScoreOnFullBoard() throws {
        let container = try makeInMemoryContainer()
        let context = container.mainContext
        for i in 0..<LeaderboardManager.maxEntries {
            LeaderboardManager.addEntry(
                LeaderboardEntry(trackId: 1, playerName: "P\(i)", timeMillis: 10_000 + i * 1000, vehicleId: "sports"),
                context: context
            )
        }
        // Worst time on the board is 19_000
        XCTAssertTrue(LeaderboardManager.isTopScore(trackId: 1, timeMillis: 18_999, context: context))
        XCTAssertFalse(LeaderboardManager.isTopScore(trackId: 1, timeMillis: 19_000, context: context))
        XCTAssertFalse(LeaderboardManager.isTopScore(trackId: 1, timeMillis: 25_000, context: context))
    }

    @MainActor
    func testIsTopScoreIsPerTrack() throws {
        let container = try makeInMemoryContainer()
        let context = container.mainContext
        for i in 0..<LeaderboardManager.maxEntries {
            LeaderboardManager.addEntry(
                LeaderboardEntry(trackId: 1, playerName: "P\(i)", timeMillis: 10_000 + i * 1000, vehicleId: "sports"),
                context: context
            )
        }
        // Track 2's board is empty — any time qualifies there
        XCTAssertTrue(LeaderboardManager.isTopScore(trackId: 2, timeMillis: 99_999, context: context))
    }

    @MainActor
    func testAddEntryTrimsBoardToMax() throws {
        let container = try makeInMemoryContainer()
        let context = container.mainContext
        for i in 0..<(LeaderboardManager.maxEntries + 3) {
            LeaderboardManager.addEntry(
                LeaderboardEntry(trackId: 1, playerName: "P\(i)", timeMillis: 10_000 + i * 1000, vehicleId: "sports"),
                context: context
            )
        }
        let descriptor = FetchDescriptor<LeaderboardEntry>(sortBy: [SortDescriptor(\LeaderboardEntry.timeMillis)])
        let entries = try context.fetch(descriptor)
        XCTAssertEqual(entries.count, LeaderboardManager.maxEntries)
        // The fastest times survive the trim
        XCTAssertEqual(entries.first?.timeMillis, 10_000)
        XCTAssertEqual(entries.last?.timeMillis, 10_000 + (LeaderboardManager.maxEntries - 1) * 1000)
    }

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

    func testTimingAccumulatesTicks() {
        let timing = TimingSystem()
        timing.start()
        for _ in 0..<60 {
            timing.tick(1.0 / 60.0)
        }
        XCTAssertEqual(timing.elapsedTime, 1.0, accuracy: 0.001)
    }

    func testTimingIgnoresTicksBeforeStart() {
        let timing = TimingSystem()
        timing.tick(0.5)
        XCTAssertEqual(timing.elapsedTime, 0)
    }

    func testTimingIgnoresTicksAfterStop() {
        let timing = TimingSystem()
        timing.start()
        timing.tick(0.5)
        let finalTime = timing.stop()
        XCTAssertEqual(finalTime, 0.5, accuracy: 0.001)
        timing.tick(0.5)
        XCTAssertEqual(timing.elapsedTime, 0.5, accuracy: 0.001)
        XCTAssertFalse(timing.isRunning)
    }

    func testTimingStartResetsElapsed() {
        let timing = TimingSystem()
        timing.start()
        timing.tick(2.0)
        timing.start()
        XCTAssertEqual(timing.elapsedTime, 0)
    }

    func testTimingReset() {
        let timing = TimingSystem()
        timing.start()
        timing.tick(0.5)
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

    func testConsumeSteerClearsDeltaButKeepsThrottle() {
        // A stationary finger fires no touchesMoved events, so the scene
        // must consume the steer delta each frame or the car drifts forever.
        let input = InputController()
        input.configure(sceneSize: CGSize(width: 800, height: 400))
        input.touchBegan(at: CGPoint(x: 600, y: 200))
        input.touchMoved(to: CGPoint(x: 600, y: 220))
        XCTAssertEqual(input.currentInput.steer, 20)
        let throttleBefore = input.currentInput.throttle

        input.consumeSteer()

        XCTAssertEqual(input.currentInput.steer, 0)
        XCTAssertEqual(input.currentInput.throttle, throttleBefore)
        XCTAssertTrue(input.isActive)
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
        XCTAssertEqual(state.dodgeCount, 0)
        XCTAssertEqual(state.maxCombo, 0)
        XCTAssertEqual(state.obstaclesHit, 0)
        XCTAssertEqual(state.topSpeedReached, 0)
    }

    func testResetPreservesSelectionForRetry() {
        // The Retry button calls reset() — it must clear per-race state
        // (especially isCrashed, which drives the finish screen header)
        // while keeping the chosen track, vehicle, and color.
        let state = GameState()
        state.selectedTrack = allTracks[2]
        state.selectedVehicle = allVehicles[1]
        state.isCrashed = true
        state.dodgeCount = 7
        state.topSpeedReached = 400

        state.reset()

        XCTAssertEqual(state.selectedTrack?.id, allTracks[2].id)
        XCTAssertEqual(state.selectedVehicle?.id, allVehicles[1].id)
        XCTAssertFalse(state.isCrashed)
        XCTAssertEqual(state.dodgeCount, 0)
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
