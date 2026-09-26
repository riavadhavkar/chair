//
//  NearbyFeedModel.swift
//  sair
//

import Foundation
import Observation

/// Owns polling `/nearby` and which production is currently shown. Keeps the
/// last good response on failure so the UI can say "updated Xm ago" instead
/// of blanking.
@MainActor
@Observable
final class NearbyFeedModel {
    private(set) var response: NearbyResponse? = NearbyFeedModel.initialResponse
    private(set) var lastUpdated: Date?
    private(set) var lastErrorOccurred = false
    private(set) var selectedIndex = 0
    private(set) var place: SavedPlace?

    private let client: SetWatchAPIClient
    private let placeStore: SavedPlaceStore
    private var pollTask: Task<Void, Never>?

    init(client: SetWatchAPIClient = SetWatchAPIClient(), placeStore: SavedPlaceStore = UserDefaultsSavedPlaceStore()) {
        self.client = client
        self.placeStore = placeStore
        self.place = placeStore.load()
    }

    /// Debug builds start from fictional sample data so the UI renders before the backend is up.
    private static var initialResponse: NearbyResponse? {
        #if DEBUG
        return .mock
        #else
        return nil
        #endif
    }

    var productions: [Production] { response?.productions ?? [] }

    var selected: Production? {
        productions.indices.contains(selectedIndex) ? productions[selectedIndex] : productions.first
    }

    var placeLabel: String { place?.label ?? response?.center.label ?? "your area" }

    /// Permits change slowly (the backend caches for 10 min), so stale means "well past a poll".
    var isStale: Bool {
        guard let lastUpdated else { return true }
        return Date().timeIntervalSince(lastUpdated) > 10 * 60
    }

    func selectNext() {
        guard !productions.isEmpty else { return }
        selectedIndex = (selectedIndex + 1) % productions.count
    }

    func selectPrevious() {
        guard !productions.isEmpty else { return }
        selectedIndex = (selectedIndex - 1 + productions.count) % productions.count
    }

    func setPlace(_ newPlace: SavedPlace) {
        place = newPlace
        placeStore.save(newPlace)
        Task { await refresh() }
    }

    func startPolling(isExpanded: @escaping () -> Bool) {
        guard pollTask == nil else { return }
        pollTask = Task { [weak self] in
            while !Task.isCancelled {
                guard let self else { return }
                await self.refresh()
                let interval: Double = isExpanded() ? 120 : 300
                try? await Task.sleep(for: .seconds(interval))
            }
        }
    }

    func stopPolling() {
        pollTask?.cancel()
        pollTask = nil
    }

    func refresh() async {
        do {
            let previousID = selected?.id
            let fresh = try await client.fetchNearby(around: place)
            response = fresh
            selectedIndex = fresh.productions.firstIndex { $0.id == previousID } ?? 0
            lastUpdated = Date()
            lastErrorOccurred = false
        } catch {
            lastErrorOccurred = true
        }
    }
}
