import CoreLocation
import Foundation

/// All data access goes through this, so the app runs on mock data until the backend is up.
protocol SetWatchService {
    func filmingToday(near center: CLLocationCoordinate2D) async throws -> [Shoot]
    func collection() async throws -> [Spot]
    func spot(id: String) async throws -> Spot
    /// Returns the result for a new check-in and for one this device already made.
    func checkIn(spotID: String, at coordinate: CLLocationCoordinate2D) async throws -> CheckInResult
    func walk(from start: CLLocationCoordinate2D, minutes: Int) async throws -> Walk
    /// MP3 narration of the walk.
    func narration(for walk: Walk) async throws -> Data
}

nonisolated enum SetWatchError: LocalizedError, Equatable {
    case tooFar(meters: Int)
    case notFound
    case notEnoughSpots
    case narrationUnavailable
    case server(status: Int)

    var errorDescription: String? {
        switch self {
        case .tooFar(let meters): "You're \(DistanceText.format(CLLocationDistance(meters))) away. Get closer to check in."
        case .notFound: "This spot doesn't exist anymore."
        case .notEnoughSpots: "Not enough filmed blocks near you for a walk. Try a longer walk or another neighborhood."
        case .narrationUnavailable: "Narration isn't available right now."
        case .server(let status): "The server had a problem (\(status)). Try again."
        }
    }
}
