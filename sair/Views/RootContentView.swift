//
//  RootContentView.swift
//  sair
//

import SwiftUI

/// Owns one persistent glass "shell" bar (the same view node in both idle
/// and expanded states — only its content and size change) plus the
/// content panel that appears beneath it once expanded. Using the same
/// node throughout, rather than swapping between two unrelated views, is
/// what makes the transition read as continuous instead of one thing
/// vanishing and another appearing elsewhere.
struct RootContentView: View {
    let windowState: NotchWindowState

    @State private var trackerModel = TransitTrackerModel()
    @State private var isShowingMap = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var pendingHoverTask: Task<Void, Never>?

    private var transitionAnimation: Animation {
        reduceMotion ? .easeInOut(duration: 0.2) : .spring(response: 0.4, dampingFraction: 0.8)
    }

    var body: some View {
        VStack(spacing: 0) {
            shell

            if windowState.isExpanded {
                ExpandedPanelView(trackerModel: trackerModel, isShowingMap: isShowingMap)
                    .transition(.opacity)
            }
        }
        .onHover { isHovering in
            guard isHovering, !windowState.isExpanded else {
                pendingHoverTask?.cancel()
                return
            }
            pendingHoverTask = Task {
                try? await Task.sleep(for: .milliseconds(500))
                guard !Task.isCancelled else { return }
                expand()
            }
        }
        .task {
            trackerModel.startPolling(isExpanded: { windowState.isExpanded })
        }
    }

    /// The persistent glass bar: idle pill and expanded header are the same
    /// view, just with different content and height, so it never has to
    /// "morph into" anything else — it just resizes and its content
    /// crossfades.
    private var shell: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(MTALineColor.l)
                .frame(width: 9, height: 9)
                .opacity(trackerModel.isStale ? 0.5 : 1)

            if windowState.isExpanded {
                Text("L Train")
                    .font(.headline)
                    .accessibilityAddTraits(.isHeader)
            } else {
                Text(arrivalText)
                    .font(.system(size: 13, weight: .medium))
                    .opacity(trackerModel.isStale ? 0.5 : 1)
                    .lineLimit(1)
                    .fixedSize()
            }

            Spacer(minLength: 0)

            if windowState.isExpanded {
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
        .padding(.horizontal, 14)
        .frame(height: windowState.isExpanded ? 40 : 36)
        .frame(maxWidth: .infinity)
        .glassEffect(.regular.interactive(), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .onTapGesture {
            if !windowState.isExpanded { expand() }
        }
        .accessibilityAddTraits(windowState.isExpanded ? [] : [.isButton])
        .accessibilityLabel(windowState.isExpanded ? "L Train" : "Expand transit details")
    }

    private var arrivalText: String {
        guard let status = trackerModel.status else { return "L · --" }
        return "L · \(status.nextArrivalMinutes) min"
    }

    private func toggleMap() {
        withAnimation(transitionAnimation) { isShowingMap.toggle() }
    }

    private func expand() {
        withAnimation(transitionAnimation) { windowState.isExpanded = true }
    }

    private func collapse() {
        withAnimation(transitionAnimation) { windowState.isExpanded = false }
    }
}
