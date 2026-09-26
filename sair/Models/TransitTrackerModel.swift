//
//  TransitTrackerModel.swift
//  sair
//

import Foundation
import Observation

/// Owns polling for one line/station pair: fetches on a cadence that
/// adapts to whether the panel is expanded (15-30s) or idle (60s), and
/// keeps the last-known status around (rather than blanking it) so the UI
/// can show "last updated Xm ago" instead of silently going stale.
@MainActor
@Observable
final class TransitTrackerModel {
    private(set) var status: TransitStatus?
    private(set) var lastUpdated: Date?
    private(set) var lastErrorOccurred = false

    let line: String
    let stationID: String
    let stationName: String

    private let client: TransitAPIClient
    private var pollTask: Task<Void, Never>?

    init(
        line: String = "L",
        stationID: String = "L03",
        stationName: String = "14 St",
        client: TransitAPIClient = TransitAPIClient()
    ) {
        self.line = line
        self.stationID = stationID
        self.stationName = stationName
        self.client = client
    }

    /// True once we either have no data at all, or the last successful
    /// fetch is old enough that it shouldn't be presented as current.
    var isStale: Bool {
        guard let lastUpdated else { return true }
        return Date().timeIntervalSince(lastUpdated) > 90
    }

    func startPolling(isExpanded: @escaping () -> Bool) {
        guard pollTask == nil else { return }
        pollTask = Task { [weak self] in
            guard let self else { return }
            while !Task.isCancelled {
                await self.refresh()
                let interval: Double = isExpanded() ? 20 : 60
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
            status = try await client.fetchStatus(line: line, station: stationID)
            lastUpdated = Date()
            lastErrorOccurred = false
        } catch {
            lastErrorOccurred = true
        }
    }
}
