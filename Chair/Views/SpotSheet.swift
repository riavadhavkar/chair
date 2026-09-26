import CoreLocation
import Foundation
import SwiftUI

/// The detail sheet for one block, opened from the map, a walk stop or the collection.
struct SpotSheet: View {
    let spotID: String

    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    @State private var loadError: String?
    @State private var checkInError: String?
    @State private var isCheckingIn = false

    var body: some View {
        Group {
            if let spot = model.spot(id: spotID) {
                content(for: spot)
            } else if let loadError {
                ContentUnavailableView("couldn't load this spot", systemImage: "exclamationmark.triangle", description: Text(loadError))
            } else {
                ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .task {
            do {
                try await model.fetchSpot(id: spotID)
            } catch {
                if model.spot(id: spotID) == nil { loadError = error.localizedDescription }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private func content(for spot: Spot) -> some View {
        ScrollView {
            VStack(spacing: 14) {
                header(spot)

                CollectibleBadge(spot: spot)
                    .sensoryFeedback(.success, trigger: spot.isCollected) { _, collected in collected }

                Text(spot.collectedAt.map { "collected \($0.formatted(date: .abbreviated, time: .omitted))" } ?? "not collected yet")
                    .font(spot.isCollected ? .subheadline.weight(.semibold) : .subheadline)
                    .foregroundStyle(spot.isCollected ? .primary : .secondary)

                VisitorCounter(spot: spot)

                facts(spot)
                    .padding(.top, 4)

                if !spot.isCollected {
                    checkInSection(spot)
                }

                if let coordinate = spot.coordinate {
                    Button("walking directions") { openDirections(to: coordinate) }
                        .frame(minHeight: 44)
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
            .padding(.bottom, 32)
        }
    }

    private func header(_ spot: Spot) -> some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(spot.name)
                    .font(.title.bold())
                    .accessibilityAddTraits(.isHeader)
                Text(spot.subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.footnote.weight(.bold))
                    .foregroundStyle(.secondary)
                    .frame(width: 32, height: 32)
                    .background(.fill.tertiary, in: Circle())
            }
            .frame(width: 44, height: 44)
            .accessibilityLabel("close")
        }
    }

    private func facts(_ spot: Spot) -> some View {
        VStack(spacing: 0) {
            if let shoot = model.shootFilmingNow(at: spot.id) {
                factRow("right now") {
                    HStack(spacing: 6) {
                        Circle().fill(.red).frame(width: 8, height: 8)
                        Text(["filming", shoot.untilText].compactMap { $0 }.joined(separator: " "))
                    }
                }
                Divider().padding(.leading, 16)
            }
            factRow("filmed") { Text("\(spot.timesFilmed) \(spot.timesFilmed == 1 ? "time" : "times") since 2012") }
            if let lastShoot = spot.lastShootText {
                Divider().padding(.leading, 16)
                factRow("last shoot") { Text(lastShoot) }
            }
        }
        .background(.fill.quaternary, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func factRow<Value: View>(_ title: String, @ViewBuilder value: () -> Value) -> some View {
        HStack {
            Text(title).foregroundStyle(.secondary)
            Spacer()
            value().fontWeight(.semibold)
        }
        .font(.subheadline)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private func checkInSection(_ spot: Spot) -> some View {
        let availability = model.availability(for: spot)
        VStack(spacing: 8) {
            Button {
                Task { await checkIn(spot) }
            } label: {
                HStack(spacing: 8) {
                    if isCheckingIn {
                        ProgressView().tint(.white)
                    } else {
                        Image(systemName: "mappin.and.ellipse")
                    }
                    Text("check in here")
                }
                .font(.headline)
                .frame(maxWidth: .infinity, minHeight: 52)
            }
            .buttonStyle(.borderedProminent)
            .buttonBorderShape(.capsule)
            .tint(.red)
            .disabled(!isReady(availability) || isCheckingIn)

            Text(checkInError ?? caption(for: availability))
                .font(.footnote)
                .foregroundStyle(checkInError == nil ? Color.secondary : Color.red)
                .multilineTextAlignment(.center)
        }
    }

    private func isReady(_ availability: AppModel.CheckInAvailability) -> Bool {
        if case .ready = availability { return true }
        return false
    }

    private func caption(for availability: AppModel.CheckInAvailability) -> String {
        switch availability {
        case .ready(let distance): "you're \(DistanceText.format(distance)) away"
        case .tooFar(let distance): "get within 100 m to check in · \(DistanceText.format(distance)) away"
        case .locating: "finding your location…"
        case .imprecise: "waiting for a more precise location…"
        case .locationDenied: "allow location access in settings to check in"
        case .unlocated: "this block can't be placed on the map yet"
        case .collected: ""
        }
    }

    private func checkIn(_ spot: Spot) async {
        isCheckingIn = true
        checkInError = nil
        do {
            try await model.checkIn(spot)
        } catch {
            checkInError = error.localizedDescription
        }
        isCheckingIn = false
    }

    private func openDirections(to coordinate: CLLocationCoordinate2D) {
        guard let url = URL(string: "https://maps.apple.com/?daddr=\(coordinate.latitude),\(coordinate.longitude)&dirflg=w") else { return }
        openURL(url)
    }
}
