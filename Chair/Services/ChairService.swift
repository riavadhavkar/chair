import CoreLocation
import Foundation

/// All data access goes through this, so the app runs on mock data until the backend is up.
protocol ChairService {
    func filmingToday(near center: CLLocationCoordinate2D) async throws -> [Shoot]
    func collection() async throws -> [Spot]
    func spot(id: String) async throws -> Spot
    /// Returns the result for a new check-in and for one this device already made.
    func checkIn(spotID: String, at coordinate: CLLocationCoordinate2D) async throws -> CheckInResult
    func walk(from start: CLLocationCoordinate2D, minutes: Int) async throws -> Walk
    /// MP3 narration of the walk.
    func narration(for walk: Walk) async throws -> Data
}

nonisolated enum ChairError: LocalizedError, Equatable {
    case tooFar(meters: Int)
    case notFound
    case notEnoughSpots
    case narrationUnavailable
    case server(status: Int)

    var errorDescription: String? {
        switch self {
        case .tooFar(let meters): "you're \(DistanceText.format(CLLocationDistance(meters))) away. get closer to check in."
        case .notFound: "this spot doesn't exist anymore."
        case .notEnoughSpots: "not enough filmed blocks near you for a walk. try a longer walk or another neighborhood."
        case .narrationUnavailable: "narration isn't available right now."
        case .server(let status): "the server had a problem (\(status)). try again."
        }
    }
}
