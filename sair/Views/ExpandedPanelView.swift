//
//  ExpandedPanelView.swift
//  sair
//

import SwiftUI

struct ExpandedPanelView: View {
    let windowState: NotchWindowState
    let trackerModel: TransitTrackerModel

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header

            if let status = trackerModel.status {
                TrainTrackerView(
                    trainProgress: schematicProgress(for: status.nextArrivalMinutes),
                    nextStopName: trackerModel.stationName,
                    etaMinutes: status.nextArrivalMinutes,
                    lineColor: MTALineColor.l
                )

                if let delayReasonRaw = status.delayReasonRaw {
                    Text(delayReasonRaw)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if let count = status.delayedCountToday, count > 0 {
                    Text("Delayed \(count)x today")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            } else {
                loadingState
            }

            if trackerModel.isStale {
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

    private var header: some View {
        HStack {
            Circle()
                .fill(MTALineColor.l)
                .frame(width: 10, height: 10)
            Text("L Train")
                .font(.headline)
            Spacer()
            Button(action: collapse) {
                Image(systemName: "chevron.up")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Collapse transit details")
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
