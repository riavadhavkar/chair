import CoreLocation
import Foundation
import MapKit
import SwiftUI

/// Home: a map of every permit filming today, with a list card underneath.
struct TodayView: View {
    @Environment(AppModel.self) private var model
    @State private var camera: MapCameraPosition = .userLocation(
        fallback: .region(MKCoordinateRegion(center: AppConfig.fallbackCenter, latitudinalMeters: 3000, longitudinalMeters: 3000))
    )
    @State private var selected: SpotRoute?

    var body: some View {
        Map(position: $camera) {
            UserAnnotation()
            ForEach(model.today) { shoot in
                Annotation(shoot.block, coordinate: shoot.coordinate) {
                    Button {
                        selected = SpotRoute(id: shoot.spotID)
                    } label: {
                        ShootPin()
                    }
                    .accessibilityLabel("\(shoot.block), \(shoot.kindText)")
                }
                .annotationTitles(.hidden)
            }
        }
        .mapStyle(.standard(pointsOfInterest: .excludingAll))
        .mapControls {
            MapUserLocationButton()
            MapCompass()
        }
        .safeAreaInset(edge: .top) {
            HStack {
                statusChip
                Spacer()
            }
            .padding(.horizontal)
        }
        .safeAreaInset(edge: .bottom) {
            TodayListCard(selected: $selected)
                .padding(.horizontal, 12)
                .padding(.bottom, 8)
        }
        .sheet(item: $selected) { route in
            SpotSheet(spotID: route.id)
        }
        .task { await model.loadToday() }
        .onChange(of: model.location.hasFix) { _, hasFix in
            if hasFix { Task { await model.loadToday() } }
        }
    }

    private var statusChip: some View {
        HStack(spacing: 8) {
            Circle().fill(.red).frame(width: 8, height: 8)
            Text("Filming today").fontWeight(.semibold)
            if model.todayState == .loaded {
                Text("· \(model.today.count) within 1 mi").foregroundStyle(.secondary)
            }
        }
        .font(.subheadline)
        .padding(.horizontal, 16)
        .frame(minHeight: 44)
        .glassEffect(.regular, in: .capsule)
        .accessibilityElement(children: .combine)
    }
}

struct ShootPin: View {
    var body: some View {
        Image(systemName: "movieclapper.fill")
            .font(.system(size: 14))
            .foregroundStyle(.white)
            .frame(width: 32, height: 32)
            .background(.red, in: Circle())
            .overlay(Circle().stroke(.white, lineWidth: 3))
            .shadow(color: .black.opacity(0.2), radius: 3, y: 2)
            .frame(width: 44, height: 44)
            .contentShape(Circle())
    }
}

/// The list of today's shoots, nearest first.
private struct TodayListCard: View {
    @Environment(AppModel.self) private var model
    @Binding var selected: SpotRoute?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text("Filming today").font(.title3.bold())
                Spacer()
                Text("nearest first").font(.footnote).foregroundStyle(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)

            switch model.todayState {
            case .idle, .loading where model.today.isEmpty:
                ProgressView().frame(maxWidth: .infinity, minHeight: 80)
            case .failed(let error) where model.today.isEmpty:
                message(title: "Can't load today's shoots", detail: error, retry: true)
            default:
                if model.today.isEmpty {
                    message(title: "Nothing filming near you today", detail: "Check back tomorrow, or plan a walk through past shoots.", retry: false)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(model.today) { shoot in
                                Button {
                                    selected = SpotRoute(id: shoot.spotID)
                                } label: {
                                    ShootRow(shoot: shoot, distance: distance(to: shoot))
                                }
                                .buttonStyle(.plain)
                                if shoot.id != model.today.last?.id {
                                    Divider().padding(.leading, 68)
                                }
                            }
                        }
                    }
                    .frame(maxHeight: 230)
                }
            }
        }
        .padding(.bottom, 8)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
    }

    private func distance(to shoot: Shoot) -> CLLocationDistance? {
        model.location.location?.distance(from: CLLocation(latitude: shoot.lat, longitude: shoot.lon))
    }

    private func message(title: String, detail: String, retry: Bool) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.headline)
            Text(detail).font(.subheadline).foregroundStyle(.secondary)
            if retry {
                Button("Try again") { Task { await model.loadToday() } }
                    .frame(minHeight: 44)
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }
}

private struct ShootRow: View {
    let shoot: Shoot
    let distance: CLLocationDistance?

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "movieclapper")
                .font(.system(size: 18))
                .foregroundStyle(.white)
                .frame(width: 40, height: 40)
                .background(.red, in: Circle())
            VStack(alignment: .leading, spacing: 2) {
                Text(shoot.block)
                    .font(.body.weight(.semibold))
                    .lineLimit(1)
                Text([shoot.kindText, shoot.untilText].compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: " · "))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer(minLength: 8)
            if let distance {
                Text(DistanceText.format(distance))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    TodayView()
        .environment(AppModel(service: MockSetWatchService()))
}
