//
//  TransitAPIClient.swift
//  sair
//

import Foundation

enum TransitAPIError: Error {
    case invalidResponse
    case serverError(status: Int)
}

/// Thin URLSession wrapper around the backend's /status endpoint. Stock
/// URLSession + async/await only, per project convention — no third-party
/// networking libraries.
struct TransitAPIClient {
    var baseURL: URL = Secrets.transitBackendBaseURL

    private let session: URLSession = {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = 8
        configuration.timeoutIntervalForResource = 8
        return URLSession(configuration: configuration)
    }()

    func fetchStatus(line: String, station: String) async throws -> TransitStatus {
        guard var components = URLComponents(url: baseURL.appendingPathComponent("status"), resolvingAgainstBaseURL: false) else {
            throw TransitAPIError.invalidResponse
        }
        components.queryItems = [
            URLQueryItem(name: "line", value: line),
            URLQueryItem(name: "station", value: station)
        ]
        guard let url = components.url else { throw TransitAPIError.invalidResponse }

        let (data, response) = try await session.data(from: url)
        guard let httpResponse = response as? HTTPURLResponse else { throw TransitAPIError.invalidResponse }
        guard (200..<300).contains(httpResponse.statusCode) else {
            throw TransitAPIError.serverError(status: httpResponse.statusCode)
        }

        return try JSONDecoder().decode(TransitStatus.self, from: data)
    }
}
