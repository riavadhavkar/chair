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
        // Above the system menu bar's own level (mainMenu = 24), not just
        // .floating (which sits below it). At .floating, a system menu bar
        // configured to auto-hide/reveal slides down *on top of* this
        // window the moment the pointer nears the top edge to hover the
        // pill — which is exactly what hovering the pill does — so the
        // pill visibly vanishes behind it. Real "lives in the notch" apps
        // (Boring Notch, NotchNook, etc.) all sit above the menu bar level
        // for this reason.
        pillWindow.level = NSWindow.Level(rawValue: NSWindow.Level.statusBar.rawValue + 1)
        pillWindow.ignoresMouseEvents = false
        pillWindow.collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary]
        pillWindow.isReleasedWhenClosed = false
        pillWindow.isMovable = false
        // Agent (LSUIElement) apps are never "key/main" in the normal
        // sense; be explicit that losing app-active status must never hide
        // this window, since that would look identical to the menu-bar
        // z-order bug above.
        pillWindow.hidesOnDeactivate = false

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

    /// Horizontally centers the pill on the notch (or on the screen's
    /// center on non-notch Macs), anchored with its TOP edge at the
    /// screen's true physical top (`screen.frame.maxY`) — i.e. the notch's
    /// own row — rather than below the menu bar. Sitting below the menu bar
    /// left a visible gap that (combined with the old sub-menu-bar window
    /// level) is exactly where an auto-revealing menu bar would slide down
    /// on top of the pill on hover. Anchoring at the physical top and
    /// rendering above the menu bar's level instead makes the pill genuinely
    /// look like it grows out of the notch. Because the vertical anchor is
    /// always (frame.maxY - height), the window's top edge stays fixed
    /// across size changes, so expanding grows purely downward.
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
        let originY = screen.frame.maxY - size.height
        let targetRect = NSRect(origin: NSPoint(x: originX, y: originY), size: size)

        window.setFrame(targetRect, display: true)
    }
}

/// Never becomes key so the pill never steals focus from whatever app is active.
private final class NotchPillWindow: NSWindow {
    override var canBecomeKey: Bool { false }
}
