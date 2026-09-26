//
//  Production.swift
//  sair
//

import CoreLocation
import Foundation

/// Mirrors the backend's `GET /nearby` response (see backend/README.md).
struct NearbyResponse: Codable, Equatable {
    let generatedAt: Date
    let center: Center
    let radiusMeters: Double
    let productions: [Production]

    struct Center: Codable, Equatable {
        let lat: Double
        let lon: Double
        let label: String?
    }
}

struct Production: Codable, Equatable, Identifiable {
    let id: String
    let category: String?
    let subcategory: String?
    let borough: String?
    let startsAt: Date?
    let endsAt: Date?
    let location: Location
    let titleHint: String?
    let match: Match?
    let summary: String
    let directionsURL: URL?
    let distanceMeters: Double?
    let shareURL: URL?

    struct Location: Codable, Equatable {
        let raw: String
        let display: String
        let lat: Double?
        let lon: Double?
        let precision: String
    }

    /// Present only for an exact TMDB title match — never a fuzzy guess.
    struct Match: Codable, Equatable {
        let source: String
        let tmdbId: Int
        let mediaType: String
        let title: String
        let year: Int?
        let overview: String?
        let genres: [String]
        let cast: [String]
        let posterURL: URL?
        let backdropURL: URL?
    }
}

extension Production {
    var isMatched: Bool { match != nil }

    /// "TV series", "feature film", "commercial"… from the permit's own category fields.
    var kindDescription: String {
        let sub = (subcategory ?? "").lowercased()
        switch sub {
        case "episodic series", "cable-episodic": return "TV series"
        case "feature": return "feature film"
        case "pilot": return "TV pilot"
        case "": return category?.lowercased() ?? "production"
        default: return sub
        }
    }

    var displayTitle: String {
        match?.title ?? titleHint ?? "A \(kindDescription) is filming nearby"
    }

    /// "TV series · Drama · 2025" when matched, otherwise the permit's own categories.
    var metaLine: String {
        if let match {
            let kind = match.mediaType == "tv" ? "TV series" : "Film"
            var parts = [kind]
            if let genre = match.genres.first { parts.append(genre) }
            if let year = match.year { parts.append(String(year)) }
            return parts.joined(separator: " · ")
        }
        return [category, subcategory, borough].compactMap { $0 }.joined(separator: " · ")
    }

    var coordinate: CLLocationCoordinate2D? {
        guard let lat = location.lat, let lon = location.lon else { return nil }
        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }

    /// A Manhattan block is ~80 m; good enough for glanceable "N blocks" copy.
    var blocksAway: Int? {
        distanceMeters.map { max(1, Int(($0 / 80).rounded())) }
    }

    var distanceText: String {
        guard let blocksAway else { return "nearby" }
        return blocksAway == 1 ? "1 block" : "\(blocksAway) blocks"
    }

    var untilText: String? {
        endsAt.map { "until \($0.formatted(date: .omitted, time: .shortened))" }
    }
}

extension NearbyResponse {
    /// Fictional sample data so the UI has something to render before the backend is deployed.
    static var mock: NearbyResponse {
        let now = Date()
        return NearbyResponse(
            generatedAt: now,
            center: Center(lat: 40.7397, lon: -73.9925, label: "Chelsea"),
            radiusMeters: 1500,
            productions: [
                Production(
                    id: "mock-matched",
                    category: "Television",
                    subcategory: "Episodic series",
                    borough: "Manhattan",
                    startsAt: now.addingTimeInterval(-3 * 3600),
                    endsAt: now.addingTimeInterval(5 * 3600),
                    location: .init(raw: "WEST 20 STREET between 5 AVENUE and 6 AVENUE", display: "W 20 St between 5 & 6 Av", lat: 40.7405, lon: -73.9925, precision: "intersection"),
                    titleHint: "The Night Desk",
                    match: .init(source: "tmdb", tmdbId: 0, mediaType: "tv", title: "The Night Desk", year: 2025, overview: "A night-shift news editor chases a story her paper would rather she dropped.", genres: ["Drama"], cast: [], posterURL: nil, backdropURL: nil),
                    summary: "The Night Desk is filming on W 20 St between 5 & 6 Av this evening.",
                    directionsURL: URL(string: "https://maps.apple.com/?daddr=40.7405,-73.9925&dirflg=w"),
                    distanceMeters: 160,
                    shareURL: nil
                ),
                Production(
                    id: "mock-permit-only",
                    category: "Television",
                    subcategory: "Episodic series",
                    borough: "Manhattan",
                    startsAt: now.addingTimeInterval(-2 * 3600),
                    endsAt: now.addingTimeInterval(8 * 3600),
                    location: .init(raw: "GREENWICH STREET between CHAMBERS STREET and WARREN STREET", display: "Greenwich St between Chambers & Warren St", lat: 40.7155, lon: -74.0105, precision: "intersection"),
                    titleHint: nil,
                    match: nil,
                    summary: "Crews are holding street parking on Greenwich St near Chambers St until this evening.",
                    directionsURL: URL(string: "https://maps.apple.com/?daddr=40.7155,-74.0105&dirflg=w"),
                    distanceMeters: 400,
                    shareURL: nil
                )
            ]
        )
    }
}
