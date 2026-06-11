//
//  Extensions.swift
//  Huddle
//
//  Created by shalinth adithyan on 26/11/25.
//

import Foundation
import UIKit
import SwiftUI

// Compiled out of Release builds — App Store binaries log nothing
func debugLog(_ message: @autoclosure () -> String) {
    #if DEBUG
    print(message())
    #endif
}

extension UIColor {
    convenience init(hex: String) {
        let scanner = Scanner(string: hex)
        var rgbValue: UInt64 = 0
        scanner.scanHexInt64(&rgbValue)
        let r = CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0
        let g = CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0
        let b = CGFloat(rgbValue & 0x0000FF) / 255.0
        self.init(red: r, green: g, blue: b, alpha: 1)
    }
}

extension Color {
    // MARK: - Brand accents (same in both modes)
    static let huddleCoral          = Color(hex: "FF8A66")
    static let huddleCoralDark      = Color(hex: "F26A45")
    static let huddlePeach          = Color(hex: "FFB68A")
    static let huddleAmber          = Color(hex: "F5A742")
    static let huddleRose           = Color(hex: "E85A7A")
    static let huddlePlum           = Color(hex: "6B2B3D")

    // MARK: - Surfaces (adaptive)
    static let huddleBackground = Color(UIColor { tc in
        tc.userInterfaceStyle == .dark ? UIColor(hex: "0E0809") : UIColor(hex: "FEF8F4")
    })
    static let huddleCard = Color(UIColor { tc in
        tc.userInterfaceStyle == .dark ? UIColor(hex: "2A1D1A") : UIColor(hex: "FFFFFF")
    })
    static let huddleSurface = Color(UIColor { tc in
        tc.userInterfaceStyle == .dark ? UIColor(hex: "1F1614") : UIColor(hex: "F5ECE8")
    })
    static let huddleGlassFill = Color(UIColor { tc in
        tc.userInterfaceStyle == .dark
            ? UIColor(hex: "281A16").withAlphaComponent(0.55)
            : UIColor(hex: "FFFFFF").withAlphaComponent(0.75)
    })

    // MARK: - Legacy compat
    static let huddlePrimaryFixed   = Color(hex: "4A1E15")
    static let huddleSecondaryFixed = Color(hex: "3A2825")

    // MARK: - Typography (adaptive)
    static let huddleTextPrimary = Color(UIColor { tc in
        tc.userInterfaceStyle == .dark ? UIColor(hex: "F5E9E2") : UIColor(hex: "1C0E0A")
    })
    static let huddleTextSecondary = Color(UIColor { tc in
        tc.userInterfaceStyle == .dark
            ? UIColor(hex: "F5E9E2").withAlphaComponent(0.72)
            : UIColor(hex: "1C0E0A").withAlphaComponent(0.68)
    })
    static let huddleTextTertiary = Color(UIColor { tc in
        tc.userInterfaceStyle == .dark
            ? UIColor(hex: "F5E9E2").withAlphaComponent(0.48)
            : UIColor(hex: "1C0E0A").withAlphaComponent(0.42)
    })

    // MARK: - Borders (adaptive)
    static let huddleBorder = Color(UIColor { tc in
        tc.userInterfaceStyle == .dark
            ? UIColor(hex: "FFB496").withAlphaComponent(0.14)
            : UIColor(hex: "D4785A").withAlphaComponent(0.22)
    })
    static let huddleOutlineVariant = Color(UIColor { tc in
        tc.userInterfaceStyle == .dark
            ? UIColor(hex: "FFB496").withAlphaComponent(0.22)
            : UIColor(hex: "D4785A").withAlphaComponent(0.32)
    })

    // MARK: - Hex init
    init(hex: String) {
        let scanner = Scanner(string: hex)
        var rgbValue: UInt64 = 0
        scanner.scanHexInt64(&rgbValue)
        let r = Double((rgbValue & 0xFF0000) >> 16) / 255.0
        let g = Double((rgbValue & 0x00FF00) >> 8)  / 255.0
        let b = Double(rgbValue & 0x0000FF)          / 255.0
        self.init(red: r, green: g, blue: b)
    }
}
