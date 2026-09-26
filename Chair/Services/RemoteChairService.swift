import CoreLocation
import Foundation

/// The backend HTTP API (see backend/README.md).
struct RemoteChairService: ChairService {
    let baseURL: URL
    let deviceID: String

    private let session: URLSession = {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 20
        return URLSession(configuration: configuration)
    }()

    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()

    private struct ErrorBody: Decodable {
        let error: String
        let distanceMeters: Int?
    }

    func filmingToday(near center: CLLocationCoordinate2D) async throws -> [Shoot] {
        try await get("today", query: [
            "lat": String(center.latitude),
            "lon": String(center.longitude),
            "radius": String(Int(AppConfig.todayRadius))
        ])
    }

    func collection() async throws -> [Spot] {
        try await get("collection", query: ["deviceID": deviceID])
    }

    func spot(id: String) async throws -> Spot {
        try await get("spots/\(id)", query: ["deviceID": deviceID])
    }

    func checkIn(spotID: String, at coordinate: CLLocationCoordinate2D) async throws -> CheckInResult {
        struct Body: Encodable { let spotID, deviceID: String; let lat, lon: Double }
        let (data, status) = try await send("checkins", method: "POST", body: Body(
            spotID: spotID, deviceID: deviceID, lat: coordinate.latitude, lon: coordinate.longitude
        ))
        switch status {
        case 200...201, 409:
            return try decoder.decode(CheckInResult.self, from: data)
        case 422:
            let body = try? decoder.decode(ErrorBody.self, from: data)
            throw ChairError.tooFar(meters: body?.distanceMeters ?? 0)
        case 404:
            throw ChairError.notFound
        default:
            throw ChairError.server(status: status)
        }
    }

    func walk(from start: CLLocationCoordinate2D, minutes: Int) async throws -> Walk {
        struct Body: Encodable { let lat, lon: Double; let minutes: Int; let deviceID: String }
        let (data, status) = try await send("walks", method: "POST", body: Body(
            lat: start.latitude, lon: start.longitude, minutes: minutes, deviceID: deviceID
        ))
        switch status {
        case 200: return try decoder.decode(Walk.self, from: data)
        case 404: throw ChairError.notEnoughSpots
        default: throw ChairError.server(status: status)
        }
    }

    func narration(for walk: Walk) async throws -> Data {
        let (data, response) = try await session.data(from: url("walks/\(walk.id)/narration"))
        let status = (response as? HTTPURLResponse)?.statusCode ?? 0
        guard status == 200 else { throw status == 503 ? ChairError.narrationUnavailable : ChairError.server(status: status) }
        return data
    }

    // MARK: - Plumbing

    private func url(_ path: String, query: [String: String] = [:]) -> URL {
        let base = baseURL.appending(path: path)
        guard !query.isEmpty else { return base }
        return base.appending(queryItems: query.sorted { $0.key < $1.key }.map { URLQueryItem(name: $0.key, value: $0.value) })
    }

    private func get<T: Decodable>(_ path: String, query: [String: String]) async throws -> T {
        let (data, response) = try await session.data(from: url(path, query: query))
        let status = (response as? HTTPURLResponse)?.statusCode ?? 0
        if status == 404 { throw ChairError.notFound }
        guard (200..<300).contains(status) else { throw ChairError.server(status: status) }
        return try decoder.decode(T.self, from: data)
    }

    private func send(_ path: String, method: String, body: some Encodable) async throws -> (Data, Int) {
        var request = URLRequest(url: url(path))
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(body)
        let (data, response) = try await session.data(for: request)
        return (data, (response as? HTTPURLResponse)?.statusCode ?? 0)
    }
}
