//
//  Extensions.swift
//  Huddle
//
//  Created by shalinth adithyan on 26/11/25.
//

import Foundation
import SwiftUI

extension Color {
    // Primary accent — coral orange (used everywhere interactive)
    static let huddleCoral = Color(hex: "E86F51")

    // Page and card backgrounds
    static let huddleBackground = Color(hex: "F9F6F3")
    static let huddleSurface = Color(hex: "F0F3FF")       // input field bg

    // Icon container fills
    static let huddlePrimaryFixed = Color(hex: "FFDAD2")  // salmon — create family icon bg
    static let huddleSecondaryFixed = Color(hex: "E0E3E6") // grey — join family icon bg

    // Typography
    static let huddleTextPrimary = Color(hex: "151C27")
    static let huddleTextSecondary = Color(hex: "57423D")
    static let huddleTextTertiary = Color(hex: "5F5E5C")

    // Borders / dividers
    static let huddleBorder = Color(hex: "E5E7EB")
    static let huddleOutlineVariant = Color(hex: "DEC0B9")

    // Legacy — still referenced in familyFeed pinned cards (rework pending)
    static let huddlePeach = Color(hex: "FFD6A5")

    init(hex: String) {
        let scanner = Scanner(string: hex)
        var rgbValue: UInt64 = 0
        scanner.scanHexInt64(&rgbValue)

        let r = Double((rgbValue & 0xFF0000) >> 16) / 255.0
        let g = Double((rgbValue & 0x00FF00) >> 8) / 255.0
        let b = Double(rgbValue & 0x0000FF) / 255.0

        self.init(red: r, green: g, blue: b)
    }
}
