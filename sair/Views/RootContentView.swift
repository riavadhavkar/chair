//
//  RootContentView.swift
//  sair
//

import SwiftUI

/// One black NotchShape that grows from the idle pill into the panel. The
/// notch row (NotchPillView) never moves; only the shape and the panel
/// content below it animate.
struct RootContentView: View {
    let windowState: NotchWindowState

    @State private var feed = NearbyFeedModel()
    @State private var pendingHoverTask: Task<Void, Never>?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var transitionAnimation: Animation {
        reduceMotion ? .easeInOut(duration: 0.2) : .spring(response: 0.4, dampingFraction: 0.8)
    }

    private var shapeSize: CGSize {
        windowState.isExpanded ? NotchLayout.expandedSize : NotchLayout.idleSize(notch: windowState.notchSize)
    }

    private var bottomRadius: CGFloat {
        windowState.isExpanded ? NotchLayout.expandedBottomRadius : NotchLayout.idleBottomRadius
    }

    var body: some View {
        ZStack(alignment: .top) {
            NotchShape(bottomRadius: bottomRadius)
                .fill(.black)

            if windowState.isExpanded {
                ExpandedPanelView(feed: feed)
                    .padding(.top, windowState.notchSize.height)
                    .transition(reduceMotion ? .opacity : .opacity.combined(with: .offset(y: -8)))
            }

            NotchPillView(
                production: feed.selected,
                isOffline: feed.lastErrorOccurred && feed.response == nil,
                notchWidth: windowState.notchSize.width
            )
            .frame(height: windowState.notchSize.height)
        }
        .frame(width: shapeSize.width, height: shapeSize.height)
        .contentShape(NotchShape(bottomRadius: bottomRadius))
        .onTapGesture {
            if !windowState.isExpanded { setExpanded(true) }
        }
        .onHover(perform: handleHover)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .task {
            feed.startPolling(isExpanded: { windowState.isExpanded })
        }
    }

    private func handleHover(_ isHovering: Bool) {
        pendingHoverTask?.cancel()
        guard isHovering != windowState.isExpanded else { return }
        let delay: Duration = isHovering ? .milliseconds(400) : .milliseconds(600)
        pendingHoverTask = Task {
            try? await Task.sleep(for: delay)
            guard !Task.isCancelled else { return }
            setExpanded(isHovering)
        }
    }

    private func setExpanded(_ expanded: Bool) {
        withAnimation(transitionAnimation) { windowState.isExpanded = expanded }
    }
}
