import CoreLocation
import Foundation

/// One permit filming today.
nonisolated struct Shoot: Codable, Identifiable, Hashable {
    let id: String
    let spotID: String
    let block: String
    let category: String?
    let subcategory: String?
    let startsAt: Date?
    let endsAt: Date?
    let lat: Double
    let lon: Double

    var coordinate: CLLocationCoordinate2D { CLLocationCoordinate2D(latitude: lat, longitude: lon) }

    var kindText: String {
        [category, subcategory].compactMap { $0 }.joined(separator: " · ")
    }

    var untilText: String? {
        endsAt.map { "until \($0.formatted(date: .omitted, time: .shortened).lowercased())" }
    }

    func isFilming(at date: Date = .now) -> Bool {
        (startsAt ?? .distantPast) <= date && date <= (endsAt ?? .distantFuture)
    }
}

/// A street block, aggregated from every permit since 2012.
nonisolated struct Spot: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let crossStreets: String?
    let neighborhood: String
    /// SF Symbol picked for this street (by Gemini at import time).
    let symbol: String?
    let lat: Double?
    let lon: Double?
    let timesFilmed: Int
    let lastFilmed: Date?
    let lastCategory: String?
    var visitorCount: Int
    var collectedAt: Date?

    var isCollected: Bool { collectedAt != nil }

    var badgeSymbol: String { symbol ?? "movieclapper" }

    var coordinate: CLLocationCoordinate2D? {
        guard let lat, let lon else { return nil }
        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }

    var location: CLLocation? {
        guard let lat, let lon else { return nil }
        return CLLocation(latitude: lat, longitude: lon)
    }

    var subtitle: String {
        [crossStreets, neighborhood].compactMap { $0 }.joined(separator: " · ")
    }

    var vibe: String {
        switch visitorCount {
        case 0: "be the first here"
        case 1...9: "secret spot"
        case 10...99: "local favorite"
        default: "a classic"
        }
    }

    /// "Mar 2026 · Television"
    var lastShootText: String? {
        guard let lastFilmed else { return nil }
        let date = lastFilmed.formatted(.dateTime.month(.abbreviated).year())
        return [date, lastCategory].compactMap { $0 }.joined(separator: " · ")
    }

    func applying(_ result: CheckInResult) -> Spot {
        var copy = self
        copy.visitorCount = result.visitorCount
        copy.collectedAt = result.collectedAt
        return copy
    }
}

nonisolated struct CheckInResult: Codable, Hashable {
    let spotID: String
    let visitorCount: Int
    let collectedAt: Date
}

nonisolated struct Walk: Codable, Identifiable, Hashable {
    let id: String
    let minutes: Int
    let stops: [Spot]
    let narrationText: String
}

/// Identifiable wrapper so a spot id can drive `.sheet(item:)`.
nonisolated struct SpotRoute: Identifiable, Hashable {
    let id: String
}

/// The three root tabs, so other views (e.g. a spot sheet's "walking
/// directions" button) can switch tabs programmatically.
nonisolated enum RootTab: Hashable {
    case today, walk, collection
}

nonisolated enum DistanceText {
    static func format(_ meters: CLLocationDistance) -> String {
        Measurement(value: meters, unit: UnitLength.meters)
            .formatted(.measurement(width: .abbreviated, usage: .road))
    }
}
