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
