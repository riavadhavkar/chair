import AVFoundation
import Foundation
import Observation

/// Plays the walk's ElevenLabs narration. If the server can't provide audio
/// (no key, offline, mock mode) it reads the same text with the device voice,
/// so Listen always works in a demo.
@Observable
final class NarrationPlayer {
    enum State { case idle, loading, playing }

    private(set) var state: State = .idle
    private(set) var isUsingDeviceVoice = false

    private var player: AVAudioPlayer?
    private let speech = AVSpeechSynthesizer()
    private var monitor: Task<Void, Never>?

    func toggle(walk: Walk, service: SetWatchService) {
        if state == .idle {
            Task { await play(walk: walk, service: service) }
        } else {
            stop()
        }
    }

    func stop() {
        monitor?.cancel()
        player?.stop()
        player = nil
        speech.stopSpeaking(at: .immediate)
        state = .idle
    }

    private func play(walk: Walk, service: SetWatchService) async {
        state = .loading
        let audio = try? await service.narration(for: walk)
        guard state == .loading else { return }

        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio)
        try? AVAudioSession.sharedInstance().setActive(true)

        if let audio, let audioPlayer = try? AVAudioPlayer(data: audio), audioPlayer.play() {
            player = audioPlayer
            isUsingDeviceVoice = false
        } else {
            let utterance = AVSpeechUtterance(string: walk.narrationText)
            utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
            speech.speak(utterance)
            isUsingDeviceVoice = true
        }
        state = .playing

        monitor = Task {
            try? await Task.sleep(for: .seconds(1))
            while !Task.isCancelled, (player?.isPlaying ?? false) || speech.isSpeaking {
                try? await Task.sleep(for: .milliseconds(400))
            }
            guard !Task.isCancelled else { return }
            player = nil
            state = .idle
        }
    }
}
