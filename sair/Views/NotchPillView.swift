//
//  NotchPillView.swift
//  sair
//

import SwiftUI

/// Idle-state content: the line color dot and next arrival — mirrors
/// Flighty's glanceable Live Activity treatment rather than a dense
/// dashboard. Purely content; the Liquid Glass capsule background and
/// morph identity are applied by the caller (RootContentView), since
/// those need to be shared with ExpandedPanelView's header for a
/// continuous idle<->expanded transition.
struct NotchPillView: View {
    let lineID: String
    let lineColor: Color
    let status: TransitStatus?
    let isStale: Bool

    init(lineID: String = "L", lineColor: Color = MTALineColor.l, status: TransitStatus? = nil, isStale: Bool = false) {
        self.lineID = lineID
        self.lineColor = lineColor
        self.status = status
        self.isStale = isStale
    }

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(lineColor)
                .frame(width: 9, height: 9)
                .opacity(isStale ? 0.5 : 1)

            Text(arrivalText)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.primary)
                .opacity(isStale ? 0.5 : 1)
                .lineLimit(1)
                .fixedSize()
        }
        .padding(.horizontal, 14)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var arrivalText: String {
        guard let status else { return "\(lineID) · --" }
        return "\(lineID) · \(status.nextArrivalMinutes) min"
    }
}

#Preview {
    NotchPillView(status: TransitStatus(line: "L", nextArrivalMinutes: 4, delayMinutes: 0, delayReasonRaw: nil, vehiclePosition: nil, delayedCountToday: nil))
        .frame(width: 180, height: 36)
        .glassEffect(.regular, in: .capsule)
        .padding()
}
