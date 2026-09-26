//
//  RouteMapView.swift
//  sair
//

import SwiftUI
import MapKit

/// Secondary, tap-to-reveal detail layer showing the literal vehicle
/// position on a real map. The primary glanceable element is
/// TrainTrackerView's schematic line — this is the "tell me more" layer
/// for someone who taps further in. Built on MapKit (native, zero
/// dependency risk) rather than Mapbox — see project notes on why.
struct RouteMapView: View {
    let vehiclePosition: TransitStatus.VehiclePosition?

    private static let fallbackCenter = CLLocationCoordinate2D(latitude: 40.7357, longitude: -73.9903)

    var body: some View {
        Map(initialPosition: cameraPosition) {
            if let vehiclePosition {
                Marker("Train", systemImage: "tram.fill", coordinate: vehiclePosition.coordinate)
            }
        }
        .mapStyle(.standard)
        .accessibilityLabel(vehiclePosition == nil ? "Map, vehicle position unavailable" : "Map showing train position")
    }

    private var cameraPosition: MapCameraPosition {
        let center = vehiclePosition?.coordinate ?? Self.fallbackCenter
        return .region(MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)))
    }
}

extension TransitStatus.VehiclePosition {
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }
}

#Preview {
    RouteMapView(vehiclePosition: .init(lat: 40.7174, lon: -73.9566))
        .frame(width: 320, height: 200)
}
