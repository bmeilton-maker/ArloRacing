import AVFoundation

class AudioManager {
    static let shared = AudioManager()

    private var players: [SoundEffect: AVAudioPlayer] = [:]
    private var enginePlayer: AVAudioPlayer?

    enum SoundEffect: String {
        case coneHit = "cone_hit"
        case skid = "skid"
        case countdownBeep = "countdown_beep"
        case raceStart = "race_start"
        case finish = "finish"
    }

    private init() {
        configureAudioSession()
    }

    private func configureAudioSession() {
        try? AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
        try? AVAudioSession.sharedInstance().setActive(true)
    }

    func play(_ effect: SoundEffect) {
        guard let url = Bundle.main.url(forResource: effect.rawValue, withExtension: "wav") else { return }
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            players[effect] = player
            player.play()
        } catch {
            // Sound file not available - silent fallback
        }
    }

    func startEngine() {
        guard let url = Bundle.main.url(forResource: "engine_loop", withExtension: "wav") else { return }
        do {
            enginePlayer = try AVAudioPlayer(contentsOf: url)
            enginePlayer?.numberOfLoops = -1
            enginePlayer?.play()
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
        players.removeAll()
    }
}
