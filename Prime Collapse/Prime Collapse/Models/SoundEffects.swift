import AVFoundation
import Observation

// Short UI sound effects, honoring the Settings toggle and the ring/silent switch.
@MainActor @Observable final class SoundEffects {
    enum Effect: String, CaseIterable {
        case ship, buy, milestone

        var volume: Float {
            switch self {
            case .ship: 0.45
            case .buy: 0.6
            case .milestone: 0.7
            }
        }

        // Fast tapping overlaps ship sounds, so it gets several voices.
        var voices: Int { self == .ship ? 4 : 1 }
    }

    @ObservationIgnored private var players: [Effect: [AVAudioPlayer]] = [:]
    @ObservationIgnored private var nextVoice: [Effect: Int] = [:]

    init() {
        // Ambient mixes with the player's own music and stays quiet on silent.
        try? AVAudioSession.sharedInstance().setCategory(.ambient)
        for effect in Effect.allCases {
            guard let url = Bundle.main.url(forResource: effect.rawValue, withExtension: "wav") else { continue }
            players[effect] = (0..<effect.voices).compactMap { _ in
                let player = try? AVAudioPlayer(contentsOf: url)
                player?.volume = effect.volume
                player?.prepareToPlay()
                return player
            }
        }
    }

    func play(_ effect: Effect) {
        // @AppStorage defaults this to true, but a never-set key reads back as false.
        guard UserDefaults.standard.object(forKey: "soundEffectsEnabled") as? Bool ?? true,
              let voices = players[effect], !voices.isEmpty else { return }
        let index = nextVoice[effect, default: 0] % voices.count
        nextVoice[effect] = index + 1
        let player = voices[index]
        player.currentTime = 0
        player.play()
    }
}
