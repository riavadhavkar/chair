//
//  VoicePlaybackModel.swift
//  sair
//

import AVFoundation
import Observation

/// Drives the voice button: synthesizes (and caches) speech for a given
/// summary, plays it back, and — critically for demo reliability — degrades
/// to a disabled `.unavailable` state instead of doing anything risky when
/// no ElevenLabs key is configured.
@MainActor
@Observable
final class VoicePlaybackModel: NSObject {
    enum State: Equatable {
        case idle
        case loading
        case playing
        case unavailable
        case failed
    }

    private(set) var state: State

    private let client: ElevenLabsClient
    private var player: AVAudioPlayer?
    private var cache: [String: Data] = [:]

    init(client: ElevenLabsClient = ElevenLabsClient()) {
        self.client = client
        state = client.apiKey == nil ? .unavailable : .idle
        super.init()
    }

    func toggle(text: String) {
        guard state != .unavailable else { return }
        if state == .playing {
            stop()
        } else {
            Task { await play(text: text) }
        }
    }

    private func play(text: String) async {
        state = .loading
        do {
            let data: Data
            if let cached = cache[text] {
                data = cached
            } else {
                data = try await client.synthesizeSpeech(text: text)
                cache[text] = data
            }
            let audioPlayer = try AVAudioPlayer(data: data)
            audioPlayer.delegate = self
            player = audioPlayer
            audioPlayer.play()
            state = .playing
        } catch {
            state = .failed
        }
    }

    private func stop() {
        player?.stop()
        player = nil
        state = .idle
    }
}

extension VoicePlaybackModel: AVAudioPlayerDelegate {
    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor in
            self.state = .idle
        }
    }
}
