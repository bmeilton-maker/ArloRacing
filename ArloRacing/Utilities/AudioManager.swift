import AVFoundation

class AudioManager {
    static let shared = AudioManager()

    private var players: [SoundEffect: AVAudioPlayer] = [:]
    private var enginePlayer: AVAudioPlayer?

    enum SoundEffect: String, CaseIterable {
        case coneHit = "cone_hit"
        case skid = "skid"
        case countdownBeep = "countdown_beep"
        case raceStart = "race_start"
        case finish = "finish"
    }

    private init() {
        configureAudioSession()
        preloadEffects()
    }

    private func configureAudioSession() {
        try? AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
        try? AVAudioSession.sharedInstance().setActive(true)
    }

    private func preloadEffects() {
        for effect in SoundEffect.allCases {
            guard let url = Bundle.main.url(forResource: effect.rawValue, withExtension: "wav"),
                  let player = try? AVAudioPlayer(contentsOf: url) else { continue }
            player.prepareToPlay()
            players[effect] = player
        }
    }

    func play(_ effect: SoundEffect) {
        guard let player = players[effect] else { return }
        player.currentTime = 0
        player.play()
    }

    func startEngine() {
        guard enginePlayer == nil else {
            enginePlayer?.play()
            return
        }
        guard let url = Bundle.main.url(forResource: "engine_loop", withExtension: "wav") else { return }
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.numberOfLoops = -1
            player.enableRate = true // required for rate/pitch changes to take effect
            player.prepareToPlay()
            player.play()
            enginePlayer = player
        } catch {
            // Sound file not available
        }
    }

    func updateEnginePitch(speedRatio: Float) {
        enginePlayer?.rate = 0.8 + speedRatio * 0.6
    }

    func stopEngine() {
        enginePlayer?.stop()
        enginePlayer = nil
    }

    func stopAll() {
        stopEngine()
        players.values.forEach { $0.stop() }
    }
}
