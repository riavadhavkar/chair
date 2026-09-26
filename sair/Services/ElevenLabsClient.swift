//
//  ElevenLabsClient.swift
//  sair
//

import Foundation

enum ElevenLabsError: Error {
    case missingAPIKey
    case invalidResponse
    case serverError(status: Int)
}

/// Text-to-speech REST call for the delay-summary voice button. Stock
/// URLSession + async/await only, per project convention.
struct ElevenLabsClient {
    var apiKey: String? = Secrets.elevenLabsAPIKey
    var voiceID: String = "21m00Tcm4TlvDq8ikWAM" // ElevenLabs' default "Rachel" voice

    private let session: URLSession = {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = 10
        configuration.timeoutIntervalForResource = 10
        return URLSession(configuration: configuration)
    }()

    func synthesizeSpeech(text: String) async throws -> Data {
        guard let apiKey else { throw ElevenLabsError.missingAPIKey }

        var request = URLRequest(url: URL(string: "https://api.elevenlabs.io/v1/text-to-speech/\(voiceID)")!)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "xi-api-key")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(["text": text, "model_id": "eleven_monolingual_v1"])

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else { throw ElevenLabsError.invalidResponse }
        guard (200..<300).contains(httpResponse.statusCode) else {
            throw ElevenLabsError.serverError(status: httpResponse.statusCode)
        }
        return data
    }
}
