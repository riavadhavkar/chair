import CoreLocation
import Foundation
import Observation

/// Shared state for all tabs, so a check-in on any screen updates the collection,
/// the map and open sheets at once.
@Observable
final class AppModel {
    enum LoadState: Equatable {
        case idle, loading, loaded
        case failed(String)
    }

    /// Whether the Check in button can be used right now, and why not.
    enum CheckInAvailability: Equatable {
        case collected
        case locationDenied
        case locating
        case imprecise
        case tooFar(CLLocationDistance)
        case ready(CLLocationDistance)
        case unlocated
    }

    let service: SetWatchService
    let location = LocationModel()

    private(set) var today: [Shoot] = []
    private(set) var todayState: LoadState = .idle
    private(set) var collection: [Spot] = []
    private(set) var collectionState: LoadState = .idle
    private var spots: [String: Spot] = [:]

    init(service: SetWatchService = AppConfig.makeService()) {
        self.service = service
    }

    var searchCenter: CLLocationCoordinate2D {
        location.location?.coordinate ?? AppConfig.fallbackCenter
    }

    func spot(id: String) -> Spot? {
        spots[id]
    }

    func shootFilmingNow(at spotID: String) -> Shoot? {
        today.first { $0.spotID == spotID && $0.isFilming() }
    }

    func loadToday() async {
        todayState = .loading
        do {
            today = try await service.filmingToday(near: searchCenter)
            todayState = .loaded
        } catch {
            todayState = .failed(error.localizedDescription)
        }
    }

    func loadCollection() async {
        if collection.isEmpty { collectionState = .loading }
        do {
            collection = try await service.collection()
            for spot in collection { spots[spot.id] = spot }
            collectionState = .loaded
        } catch {
            collectionState = .failed(error.localizedDescription)
        }
    }

    @discardableResult
    func fetchSpot(id: String) async throws -> Spot {
        let spot = try await service.spot(id: id)
        store(spot)
        return spot
    }

    func remember(_ newSpots: [Spot]) {
        for spot in newSpots where spots[spot.id] == nil { spots[spot.id] = spot }
    }

    func availability(for spot: Spot) -> CheckInAvailability {
        if spot.isCollected { return .collected }
        if spot.location == nil { return .unlocated }
        if location.isDenied { return .locationDenied }
        guard let here = location.location, let distance = location.distance(to: spot) else { return .locating }
        if here.horizontalAccuracy > AppConfig.requiredAccuracy { return .imprecise }
        return distance <= AppConfig.checkInRadius ? .ready(distance) : .tooFar(distance)
    }

    func checkIn(_ spot: Spot) async throws {
        guard case .ready = availability(for: spot), let here = location.location else { return }
        let result = try await service.checkIn(spotID: spot.id, at: here.coordinate)
        store((spots[spot.id] ?? spot).applying(result))
    }

    private func store(_ spot: Spot) {
        spots[spot.id] = spot
        if let index = collection.firstIndex(where: { $0.id == spot.id }) {
            collection[index] = spot
        } else if spot.isCollected {
            collection.append(spot)
        }
    }
}
