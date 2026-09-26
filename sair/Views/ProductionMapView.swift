//
//  ProductionMapView.swift
//  sair
//

import MapKit
import SwiftUI

/// "Where exactly": the permit's point and the user's saved place.
struct ProductionMapView: View {
    let production: Production
    let home: NearbyResponse.Center?

    var body: some View {
        Map(initialPosition: cameraPosition) {
            if let coordinate = production.coordinate {
                Marker(production.location.display, systemImage: "movieclapper", coordinate: coordinate)
                    .tint(.red)
            }
            if let home {
                Annotation(home.label ?? "You", coordinate: CLLocationCoordinate2D(latitude: home.lat, longitude: home.lon)) {
                    Circle().fill(.white).frame(width: 10, height: 10)
                        .overlay(Circle().stroke(.white.opacity(0.3), lineWidth: 6))
                }
            }
        }
        .mapStyle(.standard(emphasis: .muted))
        .environment(\.colorScheme, .dark)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .accessibilityLabel("Map showing filming on \(production.location.display)")
    }

    private var cameraPosition: MapCameraPosition {
        guard let coordinate = production.coordinate else { return .automatic }
        return .region(MKCoordinateRegion(center: coordinate, span: MKCoordinateSpan(latitudeDelta: 0.008, longitudeDelta: 0.008)))
    }
}

#Preview {
    ProductionMapView(production: NearbyResponse.mock.productions[0], home: NearbyResponse.mock.center)
        .frame(width: 500, height: 230)
}
