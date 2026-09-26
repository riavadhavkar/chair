//
//  NotchWindowState.swift
//  sair
//

import CoreGraphics
import Observation

/// Bridges the SwiftUI idle/expanded toggle to AppKit's window resizing, and
/// hands SwiftUI the physical notch size so content can sit on either side of it.
@MainActor
@Observable
final class NotchWindowState {
    var isExpanded: Bool = false {
        didSet {
            guard oldValue != isExpanded else { return }
            onExpandedChange?(isExpanded)
        }
    }

    /// Camera cutout size in points; width is 0 on Macs without a notch.
    var notchSize = CGSize(width: 0, height: 32)

    var onExpandedChange: ((Bool) -> Void)?
}
