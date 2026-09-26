//
//  AppDelegate.swift
//  sair
//

import AppKit
import SwiftUI

private enum WindowMetrics {
    static let idleSize = NSSize(width: 180, height: 36)
    static let expandedSize = NSSize(width: 320, height: 280)
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var window: NSWindow?
    private let windowState = NotchWindowState()

    func applicationDidFinishLaunching(_ notification: Notification) {
        windowState.onExpandedChange = { [weak self] isExpanded in
            self?.resize(forExpanded: isExpanded)
        }

        createWindow()
        positionWindow(size: WindowMetrics.idleSize)

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screenParametersDidChange),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )
    }

    private func createWindow() {
        let pillWindow = NotchPillWindow(
            contentRect: NSRect(origin: .zero, size: WindowMetrics.idleSize),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        pillWindow.isOpaque = false
        pillWindow.backgroundColor = .clear
        pillWindow.hasShadow = false
        pillWindow.level = .floating
        pillWindow.ignoresMouseEvents = false
        pillWindow.collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary]
        pillWindow.isReleasedWhenClosed = false

        pillWindow.contentView = NSHostingView(rootView: RootContentView(windowState: windowState))
        pillWindow.orderFrontRegardless()

        window = pillWindow
    }

    private func resize(forExpanded isExpanded: Bool) {
        window?.hasShadow = isExpanded
        let size = isExpanded ? WindowMetrics.expandedSize : WindowMetrics.idleSize
        positionWindow(size: size)
    }

    @objc private func screenParametersDidChange() {
        positionWindow(size: window?.frame.size ?? WindowMetrics.idleSize)
    }

    /// Horizontally centers the pill under the notch (or under the screen's
    /// center on non-notch Macs), anchored just below the menu bar row so it
    /// always sits in real, guaranteed-visible desktop space. Note this
    /// deliberately does NOT reuse the notch row's own vertical band
    /// (auxiliaryTopLeftArea/RightArea's y-range): that band is exactly as
    /// tall as the menu bar and centering a window on the notch horizontally
    /// while placed within that row would put most of its width directly
    /// over the physical notch cutout, which has zero display pixels
    /// underneath — the window would be genuinely invisible there, not just
    /// obscured. Sitting just below the menu bar keeps the "hangs from the
    /// notch" look without ever rendering into that dead zone. Because the
    /// vertical anchor is always (visibleFrame.maxY - height), the window's
    /// top edge stays fixed across size changes, so expanding grows purely
    /// downward.
    ///
    /// The frame change itself is applied instantly (not Core Animation
    /// -animated via `window.animator()`): animating an NSHostingView-backed
    /// window's frame at the AppKit layer fights with SwiftUI's own layout
    /// invalidation for GeometryReader/Map content and can spiral into a
    /// constraint-update crash. The idle<->expanded transition still reads
    /// as smooth because RootContentView's SwiftUI `.transition` (opacity +
    /// scale) animates the content; only the window's raw bounds snap.
    private func positionWindow(size: NSSize) {
        guard let window, let screen = NSScreen.main else { return }

        let originX: CGFloat
        if let leftArea = screen.auxiliaryTopLeftArea, let rightArea = screen.auxiliaryTopRightArea {
            let notchCenterX = (leftArea.maxX + rightArea.minX) / 2
            originX = notchCenterX - size.width / 2
        } else {
            originX = screen.frame.midX - size.width / 2
        }
        let originY = screen.visibleFrame.maxY - size.height - 6
        let targetRect = NSRect(origin: NSPoint(x: originX, y: originY), size: size)

        window.setFrame(targetRect, display: true)
    }
}

/// Never becomes key so the pill never steals focus from whatever app is active.
private final class NotchPillWindow: NSWindow {
    override var canBecomeKey: Bool { false }
}
