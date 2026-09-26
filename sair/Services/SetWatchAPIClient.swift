//
//  SetWatchAPIClient.swift
//  sair
//

import Foundation

enum SetWatchAPIError: Error {
    case invalidResponse
    case serverError(status: Int)
}

/// Stock URLSession + async/await around the backend's `GET /nearby`.
struct SetWatchAPIClient {
    var baseURL: URL = Secrets.backendBaseURL

    private let session: URLSession = {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = 8
        configuration.timeoutIntervalForResource = 12
        return URLSession(configuration: configuration)
    }()

    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()

    /// `place == nil` lets the backend use its configured default center.
    func fetchNearby(around place: SavedPlace?, radiusMeters: Int? = nil) async throws -> NearbyResponse {
        guard var components = URLComponents(url: baseURL.appendingPathComponent("nearby"), resolvingAgainstBaseURL: false) else {
            throw SetWatchAPIError.invalidResponse
        }
        var items: [URLQueryItem] = []
        if let place {
            items += [
                URLQueryItem(name: "lat", value: String(place.lat)),
                URLQueryItem(name: "lon", value: String(place.lon)),
                URLQueryItem(name: "label", value: place.label)
            ]
        }
        if let radiusMeters {
            items.append(URLQueryItem(name: "radius", value: String(radiusMeters)))
        }
        components.queryItems = items.isEmpty ? nil : items
        guard let url = components.url else { throw SetWatchAPIError.invalidResponse }

        let (data, response) = try await session.data(from: url)
        guard let httpResponse = response as? HTTPURLResponse else { throw SetWatchAPIError.invalidResponse }
        guard (200..<300).contains(httpResponse.statusCode) else {
            throw SetWatchAPIError.serverError(status: httpResponse.statusCode)
        }
        return try decoder.decode(NearbyResponse.self, from: data)
    }
}
