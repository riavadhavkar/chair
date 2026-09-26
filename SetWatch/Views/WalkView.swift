import CoreLocation
import Foundation
import MapKit
import SwiftUI

/// "Near me now": a 15/30/45-minute loop through nearby filmed blocks, narrated.
struct WalkView: View {
    @Environment(AppModel.self) private var model
    @State private var minutes = 30
    @State private var walk: Walk?
    @State private var legs: [MKPolyline] = []
    @State private var start: CLLocationCoordinate2D?
    @State private var isPlanning = false
    @State private var errorText: String?
    @State private var narration = NarrationPlayer()
    @State private var selected: SpotRoute?
    @State private var camera: MapCameraPosition = .userLocation(
        fallback: .region(MKCoordinateRegion(center: AppConfig.fallbackCenter, latitudinalMeters: 2000, longitudinalMeters: 2000))
    )

    var body: some View {
        Map(position: $camera) {
            UserAnnotation()
            ForEach(legs.indices, id: \.self) { index in
                MapPolyline(legs[index])
                    .stroke(.red, style: StrokeStyle(lineWidth: 5, lineCap: .round, lineJoin: .round))
            }
            if let walk {
                ForEach(Array(walk.stops.enumerated()), id: \.element.id) { index, stop in
                    if let coordinate = stop.coordinate {
                        Annotation(stop.name, coordinate: coordinate) {
                            Button {
                                selected = SpotRoute(id: stop.id)
                            } label: {
                                StopNumber(number: index + 1, size: 30)
                                    .overlay(Circle().stroke(.white, lineWidth: 3))
                                    .frame(width: 44, height: 44)
                            }
                            .accessibilityLabel("Stop \(index + 1), \(stop.name)")
                        }
                        .annotationTitles(.hidden)
                    }
                }
            }
        }
        .mapStyle(.standard(pointsOfInterest: .excludingAll))
        .mapControls { MapUserLocationButton() }
        .safeAreaInset(edge: .top) {
            HStack {
                lengthPicker
                Spacer()
            }
            .padding(.horizontal)
        }
        .safeAreaInset(edge: .bottom) {
            card
                .padding(.horizontal, 12)
                .padding(.bottom, 8)
        }
        .sheet(item: $selected) { route in
            SpotSheet(spotID: route.id)
        }
        .onDisappear { narration.stop() }
    }

    private var lengthPicker: some View {
        HStack(spacing: 2) {
            ForEach([15, 30, 45], id: \.self) { option in
                Button("\(option) min") {
                    minutes = option
                }
                .font(.subheadline.weight(minutes == option ? .semibold : .regular))
                .foregroundStyle(minutes == option ? Color.white : Color.primary)
                .frame(width: 70, height: 40)
                .background(minutes == option ? Color.red : Color.clear, in: Capsule())
                .accessibilityAddTraits(minutes == option ? .isSelected : [])
            }
        }
        .padding(3)
        .glassEffect(.regular, in: .capsule)
    }

    private var card: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let walk, walk.minutes == minutes {
                plannedHeader(walk)
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(Array(walk.stops.enumerated()), id: \.element.id) { index, stop in
                            Button {
                                selected = SpotRoute(id: stop.id)
                            } label: {
                                StopRow(number: index + 1, spot: model.spot(id: stop.id) ?? stop)
                            }
                            .buttonStyle(.plain)
                            if index < walk.stops.count - 1 {
                                Divider().padding(.leading, 42)
                            }
                        }
                    }
                }
                .frame(maxHeight: 240)
                Text("Stops from NYC film permits · narration written by Gemini")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Walk through filmed blocks").font(.title3.bold())
                    Text("A \(minutes)-minute loop from where you are, through the most-filmed blocks nearby.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Button {
                    Task { await plan() }
                } label: {
                    HStack {
                        if isPlanning { ProgressView().tint(.white) }
                        Text(isPlanning ? "Planning…" : "Plan my walk")
                    }
                    .font(.headline)
                    .frame(maxWidth: .infinity, minHeight: 50)
                }
                .buttonStyle(.borderedProminent)
                .buttonBorderShape(.capsule)
                .tint(.red)
                .disabled(isPlanning)
            }
            if let errorText {
                Text(errorText).font(.footnote).foregroundStyle(.red)
            }
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
    }

    private func plannedHeader(_ walk: Walk) -> some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Your \(walk.minutes)-min walk").font(.title3.bold())
                Text("\(walk.stops.count) filmed blocks")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button {
                narration.toggle(walk: walk, service: model.service)
            } label: {
                HStack(spacing: 6) {
                    switch narration.state {
                    case .idle: Image(systemName: "speaker.wave.2.fill")
                    case .loading: ProgressView().tint(.white)
                    case .playing: Image(systemName: "waveform").symbolEffect(.variableColor.iterative)
                    }
                    Text(narration.state == .playing ? "Stop" : "Listen")
                }
                .font(.subheadline.weight(.semibold))
                .padding(.horizontal, 16)
                .frame(minHeight: 44)
            }
            .buttonStyle(.borderedProminent)
            .buttonBorderShape(.capsule)
            .tint(.red)
            .accessibilityLabel(narration.state == .playing ? "Stop narration" : "Listen to the walk narration")

            Button {
                Task { await plan() }
            } label: {
                Image(systemName: "arrow.clockwise")
                    .frame(width: 44, height: 44)
            }
            .accessibilityLabel("Plan a new walk")
        }
    }

    private func plan() async {
        isPlanning = true
        errorText = nil
        narration.stop()
        let origin = model.searchCenter
        do {
            let planned = try await model.service.walk(from: origin, minutes: minutes)
            model.remember(planned.stops)
            walk = planned
            start = origin
            legs = await Self.walkingLegs(from: origin, through: planned.stops.compactMap(\.coordinate))
            withAnimation { camera = .automatic }
        } catch {
            errorText = error.localizedDescription
        }
        isPlanning = false
    }

    /// Walking directions for each leg of the loop; a straight line when directions fail.
    private static func walkingLegs(from origin: CLLocationCoordinate2D, through stops: [CLLocationCoordinate2D]) async -> [MKPolyline] {
        let points = [origin] + stops + [origin]
        var legs: [MKPolyline] = []
        for (from, to) in zip(points, points.dropFirst()) {
            let request = MKDirections.Request()
            request.source = MKMapItem(placemark: MKPlacemark(coordinate: from))
            request.destination = MKMapItem(placemark: MKPlacemark(coordinate: to))
            request.transportType = .walking
            if let route = try? await MKDirections(request: request).calculate().routes.first {
                legs.append(route.polyline)
            } else {
                legs.append(MKPolyline(coordinates: [from, to], count: 2))
            }
        }
        return legs
    }
}

private struct StopNumber: View {
    let number: Int
    var size: CGFloat = 26

    var body: some View {
        Text("\(number)")
            .font(.system(size: size * 0.5, weight: .bold))
            .foregroundStyle(.white)
            .frame(width: size, height: size)
            .background(.red, in: Circle())
    }
}

private struct StopRow: View {
    let number: Int
    let spot: Spot

    var body: some View {
        HStack(spacing: 12) {
            StopNumber(number: number)
            VStack(alignment: .leading, spacing: 1) {
                Text(spot.name).font(.body.weight(.semibold))
                Text("filmed \(spot.timesFilmed) times since 2012")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if spot.isCollected {
                Image(systemName: "checkmark.circle.fill").foregroundStyle(.red)
                    .accessibilityLabel("Collected")
            }
            Image(systemName: "chevron.right")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 10)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    WalkView()
        .environment(AppModel(service: MockSetWatchService()))
}
