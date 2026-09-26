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

    private(set) var state: State = .idle

    // Plain immutable value (not the @Observable-tracked `state`), so it's
    // safe to set from the nonisolated init below.
    private let isAvailable: Bool

    private let client: ElevenLabsClient
    private var player: AVAudioPlayer?
    private var cache: [String: Data] = [:]

    // Safe nonisolated: only assigns plain values and calls NSObject's
    // (nonisolated) super.init() — mutating the MainActor-isolated `state`
    // here (rather than via `isAvailable`) would not compile.
    nonisolated init(client: ElevenLabsClient = ElevenLabsClient()) {
        self.client = client
        self.isAvailable = client.apiKey != nil
        super.init()
    }

    /// What the UI should actually show: `.unavailable` overrides whatever
    /// `state` holds, since a missing key makes the rest of the state
    /// machine moot.
    var displayState: State {
        isAvailable ? state : .unavailable
    }

    func toggle(text: String) {
        guard isAvailable else { return }
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
