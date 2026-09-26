//
//  TransitStatus.swift
//  sair
//

import Foundation

/// Matches the backend's `GET /status?line=&station=` response shape.
struct TransitStatus: Codable, Equatable {
    let line: String
    let nextArrivalMinutes: Int
    let delayMinutes: Int
    let delayReasonRaw: String?
    let vehiclePosition: VehiclePosition?
    let delayedCountToday: Int?

    struct VehiclePosition: Codable, Equatable {
        let lat: Double
        let lon: Double
    }
}

extension TransitStatus {
    /// Shown until the backend is deployed/reachable, so the app has
    /// something real to render instead of a permanent loading state.
    static let mock = TransitStatus(
        line: "L",
        nextArrivalMinutes: 4,
        delayMinutes: 2,
        delayReasonRaw: "Minor delays due to signal problems at Bedford Av.",
        vehiclePosition: nil,
        delayedCountToday: 2
    )
}
