//
//  AppDelegate.swift
//  sair
//

import AppKit
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var window: NSWindow?
    private let windowState = NotchWindowState()
    private var pendingShrink: Task<Void, Never>?

    /// Matches RootContentView's spring so the window only shrinks once the shape has.
    private let collapseAnimationDuration: Duration = .milliseconds(450)

    func applicationDidFinishLaunching(_ notification: Notification) {
        windowState.onExpandedChange = { [weak self] isExpanded in
            self?.resize(forExpanded: isExpanded)
        }

        updateNotchSize()
        createWindow()
        positionWindow(size: currentSize(expanded: false))

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screenParametersDidChange),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )
    }

    private func createWindow() {
        let pillWindow = NotchPillWindow(
            contentRect: NSRect(origin: .zero, size: currentSize(expanded: false)),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        pillWindow.isOpaque = false
        pillWindow.backgroundColor = .clear
        pillWindow.hasShadow = false
        // Above the menu bar's level: at .floating, an auto-revealing menu bar
        // slides down over the pill exactly when the pointer hovers it.
        pillWindow.level = NSWindow.Level(rawValue: NSWindow.Level.statusBar.rawValue + 1)
        pillWindow.ignoresMouseEvents = false
        pillWindow.collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary]
        pillWindow.isReleasedWhenClosed = false
        pillWindow.isMovable = false
        pillWindow.hidesOnDeactivate = false

        let hostingView = NSHostingView(rootView: RootContentView(windowState: windowState))
        // AppDelegate owns the frame; SwiftUI's changing min size must never resize the window.
        hostingView.sizingOptions = []
        pillWindow.contentView = hostingView
        pillWindow.orderFrontRegardless()

        window = pillWindow
    }

    /// Grow the window before the SwiftUI shape animates out, and shrink it only
    /// after the shape has animated back in, so the animation is never clipped.
    /// The frame itself always snaps: animating an NSHostingView window's frame
    /// fights SwiftUI layout (see git history for the crash that caused).
    private func resize(forExpanded isExpanded: Bool) {
        pendingShrink?.cancel()
        if isExpanded {
            window?.hasShadow = true
            positionWindow(size: currentSize(expanded: true))
            return
        }
        pendingShrink = Task { [weak self, collapseAnimationDuration] in
            try? await Task.sleep(for: collapseAnimationDuration)
            guard let self, !Task.isCancelled, !self.windowState.isExpanded else { return }
            self.window?.hasShadow = false
            self.positionWindow(size: self.currentSize(expanded: false))
        }
    }

    @objc private func screenParametersDidChange() {
        updateNotchSize()
        positionWindow(size: currentSize(expanded: windowState.isExpanded))
    }

    private func currentSize(expanded: Bool) -> NSSize {
        expanded ? NotchLayout.expandedSize : NotchLayout.idleSize(notch: windowState.notchSize)
    }

    /// The camera cutout is the gap between the two auxiliary top areas; its
    /// height is the top safe-area inset. Non-notch Macs get width 0 and the
    /// menu bar's height, so the pill hangs from the top center instead.
    private func updateNotchSize() {
        guard let screen = NSScreen.main else { return }
        if let leftArea = screen.auxiliaryTopLeftArea, let rightArea = screen.auxiliaryTopRightArea {
            windowState.notchSize = CGSize(width: rightArea.minX - leftArea.maxX, height: screen.safeAreaInsets.top)
        } else {
            windowState.notchSize = CGSize(width: 0, height: NSStatusBar.system.thickness)
        }
    }

    /// Centered on the notch (or screen center), top edge flush with the
    /// physical top of the screen, so expanding grows purely downward.
    private func positionWindow(size: NSSize) {
        guard let window, let screen = NSScreen.main else { return }

        let centerX: CGFloat
        if let leftArea = screen.auxiliaryTopLeftArea, let rightArea = screen.auxiliaryTopRightArea {
            centerX = (leftArea.maxX + rightArea.minX) / 2
        } else {
            centerX = screen.frame.midX
        }
        let origin = NSPoint(x: centerX - size.width / 2, y: screen.frame.maxY - size.height)
        window.setFrame(NSRect(origin: origin, size: size), display: true)
    }
}

/// Never becomes key so the pill never steals focus from whatever app is active.
private final class NotchPillWindow: NSWindow {
    override var canBecomeKey: Bool { false }
}
