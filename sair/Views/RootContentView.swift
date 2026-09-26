//
//  RootContentView.swift
//  sair
//

import SwiftUI

/// Switches between the idle pill and expanded panel, owning the gesture
/// (tap, or hover-and-hold) that expands it, and the shared Liquid Glass
/// identity that morphs the pill's capsule into the panel's header shape
/// so the transition reads as one continuous shape growing, not one view
/// disappearing and an unrelated one appearing elsewhere.
struct RootContentView: View {
    let windowState: NotchWindowState

    @State private var trackerModel = TransitTrackerModel()
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var pendingHoverTask: Task<Void, Never>?
    @Namespace private var glassNamespace

    private var transitionAnimation: Animation {
        reduceMotion ? .easeInOut(duration: 0.2) : .spring(response: 0.4, dampingFraction: 0.8)
    }

    var body: some View {
        GlassEffectContainer(spacing: 20) {
            Group {
                if windowState.isExpanded {
                    ExpandedPanelView(windowState: windowState, trackerModel: trackerModel, glassNamespace: glassNamespace)
                        .transition(reduceMotion ? .opacity : .opacity.combined(with: .scale(scale: 0.96, anchor: .top)))
                } else {
                    NotchPillView(status: trackerModel.status, isStale: trackerModel.isStale)
                        .glassEffect(.regular.interactive(), in: .capsule)
                        .overlay {
                            // HIG "Depth": a hairline specular edge is what
                            // reads as glass rather than a flat gray pill.
                            Capsule().strokeBorder(.white.opacity(0.12), lineWidth: 0.5)
                        }
                        .glassEffectID("shell", in: glassNamespace)
                        .transition(.opacity)
                        .onTapGesture { expand() }
                        .accessibilityAddTraits(.isButton)
                        .accessibilityLabel("Expand transit details")
                }
            }
        }
        .onHover { isHovering in
            pendingHoverTask?.cancel()
            if isHovering {
                guard !windowState.isExpanded else { return }
                pendingHoverTask = Task {
                    try? await Task.sleep(for: .milliseconds(500))
                    guard !Task.isCancelled else { return }
                    expand()
                }
            } else {
                guard windowState.isExpanded else { return }
                pendingHoverTask = Task {
                    try? await Task.sleep(for: .milliseconds(600))
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
