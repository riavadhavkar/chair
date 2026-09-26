//
//  ExpandedPanelView.swift
//  sair
//

import SwiftUI

/// Expanded content only: schematic tracker or literal map, delay summary
/// + voice button, and offline/stale/loading states. The header/chrome
/// (line dot, title, map-toggle and collapse buttons) lives in
/// RootContentView's persistent "shell" so the same glass bar stays
/// onscreen continuously through the idle<->expanded transition instead
/// of being swapped for an unrelated view.
struct ExpandedPanelView: View {
    let trackerModel: TransitTrackerModel
    let isShowingMap: Bool

    @State private var voiceModel = VoicePlaybackModel()

    var body: some View {
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
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(.regularMaterial)
        .environment(\.colorScheme, .dark)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    @ViewBuilder
    private func voiceButton(text: String) -> some View {
        Button {
            voiceModel.toggle(text: text)
        } label: {
            Image(systemName: voiceIconName)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(voiceModel.displayState == .unavailable ? .tertiary : .secondary)
        }
        .buttonStyle(.plain)
        .disabled(voiceModel.displayState == .unavailable)
        .accessibilityLabel(voiceAccessibilityLabel)
    }

    private var voiceIconName: String {
        switch voiceModel.displayState {
        case .playing: "speaker.wave.2.fill"
        case .loading: "ellipsis"
        case .unavailable: "speaker.slash"
        case .failed: "exclamationmark.triangle"
        case .idle: "speaker.wave.2"
        }
    }

    private var voiceAccessibilityLabel: String {
        switch voiceModel.displayState {
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
}
