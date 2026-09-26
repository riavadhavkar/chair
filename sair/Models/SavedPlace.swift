//
//  SavedPlace.swift
//  sair
//

import Foundation

/// What "near me" means: the user's saved home/work neighborhood.
struct SavedPlace: Codable, Equatable {
    let label: String
    let lat: Double
    let lon: Double
}

protocol SavedPlaceStore {
    func load() -> SavedPlace?
    func save(_ place: SavedPlace)
}

/// Local persistence; a Backboard-backed store can conform to the same protocol.
struct UserDefaultsSavedPlaceStore: SavedPlaceStore {
    private let key = "savedPlace"
    var defaults: UserDefaults = .standard

    func load() -> SavedPlace? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(SavedPlace.self, from: data)
    }

    func save(_ place: SavedPlace) {
        guard let data = try? JSONEncoder().encode(place) else { return }
        defaults.set(data, forKey: key)
    }
}
