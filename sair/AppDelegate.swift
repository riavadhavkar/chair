//
//  AppDelegate.swift
//  sair
//

#if os(macOS)
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
        positionWindow(size: WindowMetrics.idleSize, animate: false)

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
        positionWindow(size: size, animate: true)
    }

    @objc private func screenParametersDidChange() {
        positionWindow(size: window?.frame.size ?? WindowMetrics.idleSize, animate: false)
    }

    /// Anchors the pill's top edge under the notch (or, on non-notch Macs, just
    /// below the menu bar) and horizontally centers it, so growing into the
    /// expanded panel extends purely downward rather than shifting position.
    private func positionWindow(size: NSSize, animate: Bool) {
        guard let window, let screen = NSScreen.main else { return }

        let targetRect: NSRect
        if let leftArea = screen.auxiliaryTopLeftArea, let rightArea = screen.auxiliaryTopRightArea {
            let notchCenterX = (leftArea.maxX + rightArea.minX) / 2
            let originX = notchCenterX - size.width / 2
            let originY = leftArea.maxY - size.height
            targetRect = NSRect(origin: NSPoint(x: originX, y: originY), size: size)
        } else {
            let originX = screen.frame.midX - size.width / 2
            let originY = screen.visibleFrame.maxY - size.height - 4
            targetRect = NSRect(origin: NSPoint(x: originX, y: originY), size: size)
        }

        let shouldAnimate = animate && !NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
        if shouldAnimate {
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.35
                context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                window.animator().setFrame(targetRect, display: true)
            }
        } else {
            window.setFrame(targetRect, display: true)
        }
    }
}

/// Never becomes key so the pill never steals focus from whatever app is active.
private final class NotchPillWindow: NSWindow {
    override var canBecomeKey: Bool { false }
}
#endif
