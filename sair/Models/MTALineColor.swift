//
//  MTALineColor.swift
//  sair
//

import SwiftUI

/// Fixed MTA subway line brand colors. The one deliberate exception to this
/// project's semantic-color rule — these mirror official line signage and
/// should only ever be used for the small line-indicator dot, never for chrome.
enum MTALineColor {
    static let l = Color(hex: 0xA7A9AC)
    static let numbers456 = Color(hex: 0x00933C)
    static let nqrw = Color(hex: 0xFCCC0A)
    static let bdfm = Color(hex: 0xFF6319)
    static let ace = Color(hex: 0x2850AD)
    static let g = Color(hex: 0x6CBE45)
    static let jz = Color(hex: 0x996633)
    static let numbers123 = Color(hex: 0xEE352E)
    static let number7 = Color(hex: 0xB933AD)
}

extension Color {
    init(hex: UInt) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255
        )
    }
}
