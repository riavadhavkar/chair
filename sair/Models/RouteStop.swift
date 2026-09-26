//
//  RouteStop.swift
//  sair
//

import Foundation

/// A stop along the stylized route line, positioned by fractional progress
/// (0...1) rather than real geographic coordinates — the tracker draws a
/// simplified schematic line, not a literal map.
struct RouteStop: Identifiable, Equatable {
    let id = UUID()
    let name: String
    let progress: Double
}

extension RouteStop {
    static let mockRoute: [RouteStop] = [
        RouteStop(name: "8 Av", progress: 0.0),
        RouteStop(name: "6 Av", progress: 0.22),
        RouteStop(name: "Union Sq", progress: 0.45),
        RouteStop(name: "14 St", progress: 0.68),
        RouteStop(name: "Bedford Av", progress: 1.0)
    ]
}
