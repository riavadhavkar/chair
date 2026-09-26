import CoreLocation
import Foundation
import Observation

/// Live location via CLLocationUpdate (no delegate). Starting it asks for
/// When-In-Use permission the first time.
@Observable
final class LocationModel {
    private(set) var location: CLLocation?
    private(set) var isDenied = false

    private var session: CLServiceSession?
    private var updates: Task<Void, Never>?

    var hasFix: Bool { location != nil }

    func start() {
        guard updates == nil else { return }
        session = CLServiceSession(authorization: .whenInUse)
        updates = Task {
            do {
                for try await update in CLLocationUpdate.liveUpdates() {
                    if update.authorizationDenied || update.authorizationDeniedGlobally {
                        isDenied = true
                    }
                    if let newLocation = update.location {
                        location = newLocation
                        isDenied = false
                    }
                }
            } catch {
                updates = nil
            }
        }
    }

    func distance(to spot: Spot) -> CLLocationDistance? {
        guard let location, let target = spot.location else { return nil }
        return location.distance(from: target)
    }
}
