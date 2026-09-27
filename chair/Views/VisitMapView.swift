import CoreLocation
import Foundation
import MapKit
import SwiftUI

/// "my map": every block you've collected, the area you've explored around them,
/// and the trail between visits in the order you made them. The replay slider
/// (or play button) walks back through your history one visit at a time.
struct VisitMapView: View {
    let spots: [Spot]
    @Binding var selected: SpotRoute?

    @State private var shownCount: Double = 0
    @State private var showsMissing = false
    @State private var replay: Task<Void, Never>?
    @State private var camera: MapCameraPosition = .automatic

    /// Your visits, oldest first.
    private var visits: [Spot] {
        spots.filter { $0.isCollected && $0.coordinate != nil }
            .sorted { ($0.collectedAt ?? .distantPast) < ($1.collectedAt ?? .distantPast) }
    }

    private var shownVisits: [Spot] {
        Array(visits.prefix(max(1, Int(shownCount.rounded()))))
    }

    var body: some View {
        Map(position: $camera) {
            UserAnnotation()

            if showsMissing {
                ForEach(spots.filter { !$0.isCollected && $0.coordinate != nil }) { spot in
                    Annotation(spot.name, coordinate: spot.coordinate!) {
                        Button { selected = SpotRoute(id: spot.id) } label: {
                            SpotBadge(symbol: spot.badgeSymbol, isCollected: false, size: 22)
                                .frame(width: 44, height: 44)
                        }
                        .accessibilityLabel("\(spot.name), not collected")
                    }
                    .annotationTitles(.hidden)
                }
            }

            if !visits.isEmpty {
                ForEach(shownVisits) { spot in
                    MapCircle(center: spot.coordinate!, radius: 160)
                        .foregroundStyle(.red.opacity(0.14))
                        .stroke(.red.opacity(0.3), lineWidth: 1)
                }

                if shownVisits.count > 1 {
                    MapPolyline(coordinates: shownVisits.compactMap(\.coordinate))
                        .stroke(.red, style: StrokeStyle(lineWidth: 2, lineCap: .round, dash: [5, 5]))
                }

                ForEach(shownVisits) { spot in
                    Annotation(spot.name, coordinate: spot.coordinate!) {
                        Button { selected = SpotRoute(id: spot.id) } label: {
                            SpotBadge(symbol: spot.badgeSymbol, isCollected: true, size: 36)
                                .frame(width: 44, height: 44)
                        }
                        .accessibilityLabel("\(spot.name), collected \(spot.collectedAt?.formatted(date: .abbreviated, time: .omitted) ?? "")")
                    }
                    .annotationTitles(.hidden)
                }
            }
        }
        .mapStyle(.standard(emphasis: .muted, pointsOfInterest: .excludingAll))
        .mapControls { MapUserLocationButton() }
        .safeAreaInset(edge: .bottom) {
            card
                .padding(.horizontal, 12)
                .padding(.bottom, 8)
        }
        .onAppear { shownCount = Double(visits.count) }
        .onChange(of: visits.count) { _, count in shownCount = Double(count) }
        .onDisappear { replay?.cancel() }
    }

    @ViewBuilder
    private var card: some View {
        VStack(alignment: .leading, spacing: 12) {
            if visits.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("no visits yet").font(.headline)
                    Text("check in at a filmed block and it shows up here, with the area you've explored around it.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            } else {
                stats
                if visits.count > 1 { replayControls }
                recentVisits
            }
            Toggle("show blocks you haven't collected", isOn: $showsMissing.animation())
                .font(.subheadline)
                .tint(.red)
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
    }

    private var stats: some View {
        let neighborhoods = Set(visits.map(\.neighborhood)).count
        let since = visits.first?.collectedAt?.formatted(.dateTime.month(.abbreviated).year()) ?? ""
        return HStack(spacing: 16) {
            stat("\(visits.count)", visits.count == 1 ? "block" : "blocks")
            stat("\(neighborhoods)", neighborhoods == 1 ? "neighborhood" : "neighborhoods")
            stat(since, "first visit")
        }
    }

    private func stat(_ value: String, _ label: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value).font(.title3.bold()).monospacedDigit()
            Text(label).font(.caption).foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .combine)
    }

    private var replayControls: some View {
        HStack(spacing: 12) {
            Button {
                replay?.cancel()
                replay = Task { await playReplay() }
            } label: {
                Image(systemName: "play.fill").frame(width: 44, height: 44)
            }
            .accessibilityLabel("replay your visits")

            VStack(alignment: .leading, spacing: 2) {
                Slider(value: $shownCount, in: 1...Double(visits.count), step: 1)
                    .tint(.red)
                    .accessibilityLabel("visits shown")
                    .accessibilityValue("\(shownVisits.count) of \(visits.count)")
                Text(replayCaption).font(.caption).foregroundStyle(.secondary).monospacedDigit()
            }
        }
    }

    private var replayCaption: String {
        let last = shownVisits.last
        let date = last?.collectedAt?.formatted(date: .abbreviated, time: .omitted) ?? ""
        return "visit \(shownVisits.count) of \(visits.count) · \(last?.name ?? "") · \(date)"
    }

    private var recentVisits: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(visits.reversed()) { spot in
                    Button {
                        selected = SpotRoute(id: spot.id)
                    } label: {
                        HStack(spacing: 8) {
                            SpotBadge(symbol: spot.badgeSymbol, isCollected: true, size: 28)
                            VStack(alignment: .leading, spacing: 0) {
                                Text(spot.name).font(.footnote.weight(.semibold))
                                Text(spot.collectedAt?.formatted(date: .abbreviated, time: .omitted) ?? "")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 6)
                        .padding(.leading, 6)
                        .padding(.trailing, 12)
                        .background(.fill.tertiary, in: Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func playReplay() async {
        for count in 1...visits.count {
            guard !Task.isCancelled else { return }
            withAnimation(.easeInOut(duration: 0.4)) { shownCount = Double(count) }
            try? await Task.sleep(for: .milliseconds(700))
        }
    }
}

#Preview {
    VisitMapView(spots: [], selected: .constant(nil))
        .environment(AppModel(service: MockChairService()))
}
