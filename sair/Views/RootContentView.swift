//
//  RootContentView.swift
//  sair
//

import SwiftUI

/// Switches between the idle pill and expanded panel, owning the gestures
/// (tap, or hover-and-hold) that drive the transition between them.
struct RootContentView: View {
    let windowState: NotchWindowState

    @State private var trackerModel = TransitTrackerModel()
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var pendingHoverTask: Task<Void, Never>?

    private var transitionAnimation: Animation {
        reduceMotion ? .easeInOut(duration: 0.2) : .spring(response: 0.4, dampingFraction: 0.8)
    }

    var body: some View {
        Group {
            if windowState.isExpanded {
                ExpandedPanelView(windowState: windowState, trackerModel: trackerModel)
                    .transition(reduceMotion ? .opacity : .opacity.combined(with: .scale(scale: 0.96, anchor: .top)))
            } else {
                NotchPillView(status: trackerModel.status, isStale: trackerModel.isStale)
                    .transition(.opacity)
                    .onTapGesture { expand() }
                    .accessibilityAddTraits(.isButton)
                    .accessibilityLabel("Expand transit details")
            }
        }
        .onHover { isHovering in
            pendingHoverTask?.cancel()
            if isHovering, !windowState.isExpanded {
                pendingHoverTask = Task {
                    try? await Task.sleep(for: .milliseconds(500))
                    guard !Task.isCancelled else { return }
                    expand()
                }
            } else if !isHovering, windowState.isExpanded {
                pendingHoverTask = Task {
                    try? await Task.sleep(for: .milliseconds(400))
                    guard !Task.isCancelled else { return }
                    collapse()
                }
            }
        }
        .task {
            trackerModel.startPolling(isExpanded: { windowState.isExpanded })
        }
    }

    private func expand() {
        withAnimation(transitionAnimation) { windowState.isExpanded = true }
    }

    private func collapse() {
        withAnimation(transitionAnimation) { windowState.isExpanded = false }
    }
}
