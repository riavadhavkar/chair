//
//  ExpandedPanelView.swift
//  sair
//

import SwiftUI

/// Everything below the notch row when expanded: the production card (or map),
/// controls, pager and source attribution — or the empty/offline/loading states.
struct ExpandedPanelView: View {
    let feed: NearbyFeedModel

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.openURL) private var openURL
    @State private var isShowingMap = false
    @State private var voiceModel = VoicePlaybackModel()

    var body: some View {
        Group {
            if let production = feed.selected {
                productionContent(production)
            } else if feed.response != nil {
                emptyState
            } else if feed.lastErrorOccurred {
                offlineState
            } else {
                ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .padding(.horizontal, NotchLayout.shoulder + 20)
        .padding(.top, 16)
        .padding(.bottom, 20)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .foregroundStyle(.white)
        .environment(\.colorScheme, .dark)
    }

    private func productionContent(_ production: Production) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            if isShowingMap {
                ProductionMapView(production: production, home: feed.response?.center)
                    .frame(maxHeight: .infinity)
            } else {
                ProductionCardView(production: production)
                    .id(production.id)
                    .transition(.opacity)
            }

            controls(for: production)

            Text(footerText(for: production))
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    private func controls(for production: Production) -> some View {
        HStack(spacing: 8) {
            if let directionsURL = production.directionsURL {
                Button {
                    openURL(directionsURL)
                } label: {
                    Label("Directions", systemImage: "location.north.fill")
                        .font(.callout.weight(.semibold))
                        .padding(.horizontal, 16)
                        .frame(height: 36)
                        .background(.white, in: Capsule())
                        .foregroundStyle(.black)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Walking directions in Maps")
            }

            circleButton(systemImage: voiceIconName, label: voiceAccessibilityLabel) {
                voiceModel.toggle(text: production.summary)
            }
            .disabled(voiceModel.state == .unavailable)

            circleButton(systemImage: isShowingMap ? "rectangle.portrait" : "map", label: isShowingMap ? "Show production card" : "Show map") {
                withAnimation(panelAnimation) { isShowingMap.toggle() }
            }

            Spacer()

            if feed.productions.count > 1 {
                pager
            }
        }
    }

    private var pager: some View {
        HStack(spacing: 4) {
            Button { withAnimation(panelAnimation) { feed.selectPrevious() } } label: {
                Image(systemName: "chevron.left").frame(width: 28, height: 28).contentShape(Rectangle())
            }
            .accessibilityLabel("Previous production")
            Text("\(feed.selectedIndex + 1) of \(feed.productions.count)")
                .font(.caption)
                .monospacedDigit()
                .foregroundStyle(.secondary)
            Button { withAnimation(panelAnimation) { feed.selectNext() } } label: {
                Image(systemName: "chevron.right").frame(width: 28, height: 28).contentShape(Rectangle())
            }
            .accessibilityLabel("Next production")
        }
        .buttonStyle(.plain)
        .font(.system(size: 12, weight: .semibold))
    }

    private func circleButton(systemImage: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 14, weight: .medium))
                .frame(width: 36, height: 36)
                .background(.white.opacity(0.08), in: Circle())
                .overlay(Circle().strokeBorder(.white.opacity(0.16), lineWidth: 0.5))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }

    private var emptyState: some View {
        HStack(spacing: 14) {
            Image(systemName: "movieclapper")
                .font(.system(size: 24, weight: .light))
                .foregroundStyle(.secondary)
            VStack(alignment: .leading, spacing: 3) {
                Text("Nothing filming near you today").font(.headline)
                Text("\(feed.placeLabel) · \(checkedText)").font(.caption).foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
    }

    private var offlineState: some View {
        HStack(spacing: 12) {
            Image(systemName: "wifi.slash")
                .font(.system(size: 20))
                .foregroundStyle(.secondary)
            VStack(alignment: .leading, spacing: 3) {
                Text("Can’t reach live data").font(.headline)
                Text(checkedText).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Button("Retry") { Task { await feed.refresh() } }
                .buttonStyle(.bordered)
                .controlSize(.small)
        }
    }

    private var checkedText: String {
        guard let lastUpdated = feed.lastUpdated else { return "not checked yet" }
        let minutes = max(0, Int(Date().timeIntervalSince(lastUpdated) / 60))
        return minutes == 0 ? "checked just now" : "checked \(minutes) min ago"
    }

    private func footerText(for production: Production) -> String {
        var parts = [production.isMatched
            ? "Title & poster via TMDB · location & hours from NYC film permit"
            : "No title on this permit — productions often file under working names"]
        if feed.isStale, feed.lastUpdated != nil { parts.append(checkedText) }
        return parts.joined(separator: " · ")
    }

    private var panelAnimation: Animation {
        reduceMotion ? .easeInOut(duration: 0.2) : .spring(response: 0.4, dampingFraction: 0.85)
    }

    private var voiceIconName: String {
        switch voiceModel.state {
        case .playing: "speaker.wave.2.fill"
        case .loading: "ellipsis"
        case .unavailable: "speaker.slash"
        case .failed: "exclamationmark.triangle"
        case .idle: "speaker.wave.2"
        }
    }

    private var voiceAccessibilityLabel: String {
        switch voiceModel.state {
        case .playing: "Stop spoken summary"
        case .loading: "Loading spoken summary"
        case .unavailable: "Voice unavailable, no ElevenLabs key configured"
        case .failed: "Play spoken summary, previous attempt failed"
        case .idle: "Play spoken summary"
        }
    }
}
