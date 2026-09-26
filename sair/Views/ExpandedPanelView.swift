//
//  ExpandedPanelView.swift
//  sair
//

import SwiftUI

struct ExpandedPanelView: View {
    let windowState: NotchWindowState
    let trackerModel: TransitTrackerModel
    let glassNamespace: Namespace.ID

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isShowingMap = false
    @State private var voiceModel = VoicePlaybackModel()

    private let headerHeight: CGFloat = 40

    var body: some View {
        // Two layers, per HIG: Liquid Glass is reserved for the functional
        // chrome (header/controls) that floats above the content layer;
        // the content layer itself (tracker/map/status text) uses a
        // standard material, never glassEffect.
        ZStack(alignment: .top) {
            content
                .padding(.top, headerHeight + 10)
                .padding([.horizontal, .bottom], 16)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .background(.regularMaterial)
                .environment(\.colorScheme, .dark)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

            header
                .padding(.horizontal, 14)
                .frame(height: headerHeight)
                .glassEffect(.regular, in: .rect(cornerRadius: 16, style: .continuous))
                .glassEffectID("shell", in: glassNamespace)
                .padding(.horizontal, 6)
                .padding(.top, 6)
        }
    }

    @ViewBuilder
    private var content: some View {
        VStack(alignment: .leading, spacing: 14) {
            if isShowingMap {
                RouteMapView(vehiclePosition: trackerModel.status?.vehiclePosition)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let status = trackerModel.status {
                TrainTrackerView(
                    trainProgress: schematicProgress(for: status.nextArrivalMinutes),
                    nextStopName: trackerModel.stationName,
                    etaMinutes: status.nextArrivalMinutes,
                    lineColor: MTALineColor.l
                )

                if let delayReasonRaw = status.delayReasonRaw {
                    HStack(alignment: .top, spacing: 6) {
                        Text(delayReasonRaw)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer(minLength: 0)
                        voiceButton(text: delayReasonRaw)
                    }
                }

                if let count = status.delayedCountToday, count > 0 {
                    Text("Delayed \(count)x today")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            } else {
                loadingState
            }

            if !isShowingMap, trackerModel.isStale {
                Text(lastUpdatedText)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)
        }
    }

    private var header: some View {
        HStack {
            Circle()
                .fill(MTALineColor.l)
                .frame(width: 10, height: 10)
            Text("L Train")
                .font(.headline)
                .accessibilityAddTraits(.isHeader)
            Spacer()
            Button(action: toggleMap) {
                Image(systemName: isShowingMap ? "list.bullet" : "map")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(isShowingMap ? "Show tracker" : "Show route map")

            Button(action: collapse) {
                Image(systemName: "chevron.up")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Collapse transit details")
        }
    }

    private func toggleMap() {
        withAnimation(reduceMotion ? .easeInOut(duration: 0.2) : .spring(response: 0.4, dampingFraction: 0.8)) {
            isShowingMap.toggle()
        }
    }

    @ViewBuilder
    private func voiceButton(text: String) -> some View {
        Button {
            voiceModel.toggle(text: text)
        } label: {
            Image(systemName: voiceIconName)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(voiceModel.state == .unavailable ? .tertiary : .secondary)
        }
        .buttonStyle(.plain)
        .disabled(voiceModel.state == .unavailable)
        .accessibilityLabel(voiceAccessibilityLabel)
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
        case .playing: "Stop spoken delay summary"
        case .loading: "Loading spoken delay summary"
        case .unavailable: "Voice unavailable, no ElevenLabs key configured"
        case .failed: "Play spoken delay summary, previous attempt failed"
        case .idle: "Play spoken delay summary"
        }
    }

    private var loadingState: some View {
        VStack(spacing: 6) {
            ProgressView()
            Text(trackerModel.lastErrorOccurred ? "Can't reach the transit backend." : "Loading arrival data…")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.vertical, 24)
        .accessibilityElement(children: .combine)
    }

    private var lastUpdatedText: String {
        guard let lastUpdated = trackerModel.lastUpdated else { return "Not yet updated" }
        let minutesAgo = max(0, Int(Date().timeIntervalSince(lastUpdated) / 60))
        return minutesAgo == 0 ? "Updated just now" : "Last updated \(minutesAgo)m ago"
    }

    /// The backend reports minutes-to-arrival, not a literal position along
    /// our stylized route, so approximate schematic progress from that —
    /// consistent with TrainTrackerView being a schematic, not a literal map.
    private func schematicProgress(for etaMinutes: Int) -> Double {
        let assumedMaxWaitMinutes = 10.0
        return min(max(1 - Double(etaMinutes) / assumedMaxWaitMinutes, 0), 1)
    }

    private func collapse() {
        withAnimation(reduceMotion ? .easeInOut(duration: 0.2) : .spring(response: 0.4, dampingFraction: 0.8)) {
            windowState.isExpanded = false
        }
    }
}
