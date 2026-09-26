//
//  NotchWindowState.swift
//  sair
//

import Observation

/// Bridges the SwiftUI idle/expanded toggle to AppKit's window resizing.
/// Uses a plain closure rather than Combine, per project convention.
@MainActor
@Observable
final class NotchWindowState {
    var isExpanded: Bool = false {
        didSet {
            guard oldValue != isExpanded else { return }
            onExpandedChange?(isExpanded)
        }
    }

    var onExpandedChange: ((Bool) -> Void)?
}
