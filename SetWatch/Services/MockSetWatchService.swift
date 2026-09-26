import CoreLocation
import Foundation

/// Sample data matching the design canvas, so every screen works with no backend.
/// Counts and coordinates are placeholders. To test check-in in the simulator, set
/// Features ▸ Location ▸ Custom Location to a spot's coordinate below.
final class MockSetWatchService: SetWatchService {
    private var spots: [String: Spot]
    private let shoots: [Shoot]

    init() {
        func spot(_ id: String, _ name: String, _ cross: String, _ hood: String, _ lat: Double, _ lon: Double,
                  filmed: Int, last: String, category: String, visitors: Int, collected: String? = nil) -> Spot {
            Spot(id: id, name: name, crossStreets: cross, neighborhood: hood, lat: lat, lon: lon,
                 timesFilmed: filmed, lastFilmed: Self.date(last), lastCategory: category,
                 visitorCount: visitors, collectedAt: collected.flatMap(Self.date))
        }
        let all = [
            spot("bedford", "Bedford St", "Commerce St – Barrow St", "West Village", 40.7318, -74.0050, filmed: 71, last: "2026-05-12", category: "Television", visitors: 38, collected: "2026-09-12"),
            spot("commerce", "Commerce St", "Bedford St – Barrow St", "West Village", 40.7315, -74.0058, filmed: 18, last: "2025-01-20", category: "Film", visitors: 4, collected: "2026-09-26"),
            spot("perry", "Perry St", "Bleecker St – W 4 St", "West Village", 40.7355, -74.0030, filmed: 57, last: "2026-07-02", category: "Television", visitors: 126, collected: "2026-08-30"),
            spot("bank", "Bank St", "Greenwich St – Washington St", "West Village", 40.7368, -74.0090, filmed: 41, last: "2026-04-18", category: "Film", visitors: 12),
            spot("charles", "Charles St", "Bleecker St – W 4 St", "West Village", 40.7347, -74.0025, filmed: 35, last: "2025-11-03", category: "Commercial", visitors: 0),
            spot("grove", "Grove St", "Bedford St – Bleecker St", "West Village", 40.7330, -74.0040, filmed: 63, last: "2026-03-09", category: "Television", visitors: 212),
            spot("bleecker", "Bleecker St", "Christopher St – Grove St", "West Village", 40.7337, -74.0035, filmed: 88, last: "2026-08-21", category: "Television", visitors: 97),
            spot("w20", "W 20 St", "5 Av – 6 Av", "Chelsea", 40.7403, -73.9930, filmed: 52, last: "2026-09-01", category: "Television", visitors: 31, collected: "2026-09-20"),
            spot("9av", "9 Av", "W 22 St – W 23 St", "Chelsea", 40.7465, -74.0010, filmed: 29, last: "2026-02-14", category: "Film", visitors: 7),
            spot("w22", "W 22 St", "9 Av – 10 Av", "Chelsea", 40.7470, -74.0040, filmed: 24, last: "2025-12-01", category: "Television", visitors: 2),
            spot("greene", "Greene St", "Prince St – Spring St", "SoHo", 40.7245, -74.0005, filmed: 66, last: "2026-06-11", category: "Commercial", visitors: 54),
            spot("mercer", "Mercer St", "Prince St – Spring St", "SoHo", 40.7243, -73.9993, filmed: 47, last: "2026-01-30", category: "Film", visitors: 9),
            spot("crosby", "Crosby St", "Prince St – Spring St", "SoHo", 40.7228, -73.9970, filmed: 58, last: "2026-07-19", category: "Television", visitors: 21),
            spot("e10", "E 10 St", "1 Av – 2 Av", "East Village", 40.7288, -73.9855, filmed: 1, last: "2026-09-26", category: "Commercial", visitors: 0)
        ]
        spots = Dictionary(uniqueKeysWithValues: all.map { ($0.id, $0) })

        let today = Calendar.current.startOfDay(for: .now)
        func at(_ hour: Int) -> Date { today.addingTimeInterval(TimeInterval(hour * 3600)) }
        shoots = [
            Shoot(id: "p1", spotID: "w20", block: "W 20 St between 5 Av & 6 Av", category: "Television", subcategory: "Episodic series", startsAt: at(7), endsAt: at(21), lat: 40.7403, lon: -73.9930),
            Shoot(id: "p2", spotID: "perry", block: "Perry St between Bleecker St & W 4 St", category: "Film", subcategory: "Feature", startsAt: at(6), endsAt: at(18), lat: 40.7355, lon: -74.0030),
            Shoot(id: "p3", spotID: "e10", block: "E 10 St between 1 Av & 2 Av", category: "Commercial", subcategory: nil, startsAt: at(8), endsAt: at(16), lat: 40.7288, lon: -73.9855)
        ]
    }

    private static func date(_ day: String) -> Date? {
        try? Date("\(day)T16:00:00Z", strategy: .iso8601)
    }

    private func pause() async {
        try? await Task.sleep(for: .milliseconds(300))
    }

    func filmingToday(near center: CLLocationCoordinate2D) async throws -> [Shoot] {
        await pause()
        let here = CLLocation(latitude: center.latitude, longitude: center.longitude)
        return shoots.sorted {
            here.distance(from: CLLocation(latitude: $0.lat, longitude: $0.lon)) <
                here.distance(from: CLLocation(latitude: $1.lat, longitude: $1.lon))
        }
    }

    func collection() async throws -> [Spot] {
        await pause()
        return spots.values.filter { $0.id != "e10" || $0.isCollected }
    }

    func spot(id: String) async throws -> Spot {
        await pause()
        guard let spot = spots[id] else { throw SetWatchError.notFound }
        return spot
    }

    func checkIn(spotID: String, at coordinate: CLLocationCoordinate2D) async throws -> CheckInResult {
        await pause()
        guard let spot = spots[spotID], let location = spot.location else { throw SetWatchError.notFound }
        let distance = location.distance(from: CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude))
        guard distance <= 150 else { throw SetWatchError.tooFar(meters: Int(distance)) }
        if let collectedAt = spot.collectedAt {
            return CheckInResult(spotID: spotID, visitorCount: spot.visitorCount, collectedAt: collectedAt)
        }
        let result = CheckInResult(spotID: spotID, visitorCount: spot.visitorCount + 1, collectedAt: .now)
        spots[spotID] = spot.applying(result)
        return result
    }

    func walk(from start: CLLocationCoordinate2D, minutes: Int) async throws -> Walk {
        await pause()
        let count = [15: 3, 30: 5, 45: 6][minutes] ?? 5
        let here = CLLocation(latitude: start.latitude, longitude: start.longitude)
        let nearby = spots.values
            .filter { ($0.location?.distance(from: here) ?? .infinity) <= Double(minutes) * 80 * 0.4 }
            .sorted { $0.timesFilmed > $1.timesFilmed }
            .prefix(count)
        guard nearby.count >= 2 else { throw SetWatchError.notEnoughSpots }

        var remaining = Array(nearby)
        var ordered: [Spot] = []
        var current = here
        while !remaining.isEmpty {
            let index = remaining.indices.min {
                remaining[$0].location!.distance(from: current) < remaining[$1].location!.distance(from: current)
            }!
            let next = remaining.remove(at: index)
            ordered.append(next)
            current = next.location!
        }

        let narration = (["Welcome to your \(minutes)-minute Set Watch walk."] + ordered.enumerated().map { index, spot in
            "Stop \(index + 1): \(spot.name), \(spot.crossStreets ?? spot.neighborhood). Filmed \(spot.timesFilmed) times since 2012."
        } + ["Check in at each block to add it to your collection."]).joined(separator: " ")
        return Walk(id: UUID().uuidString, minutes: minutes, stops: ordered, narrationText: narration)
    }

    func narration(for walk: Walk) async throws -> Data {
        throw SetWatchError.narrationUnavailable
    }
}
