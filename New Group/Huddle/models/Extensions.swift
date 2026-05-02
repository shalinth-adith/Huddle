//
//  Extensions.swift
//  Huddle
//
//  Created by shalinth adithyan on 26/11/25.
//

import Foundation
import UIKit
import SwiftUI

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
    // MARK: - Lush palette (always dark)
    static let huddleCoral          = Color(hex: "FF8A66")
    static let huddleCoralDark      = Color(hex: "F26A45")
    static let huddlePeach          = Color(hex: "FFB68A")
    static let huddleAmber          = Color(hex: "F5A742")
    static let huddleRose           = Color(hex: "E85A7A")
    static let huddlePlum           = Color(hex: "6B2B3D")

    // MARK: - Surfaces
    static let huddleBackground     = Color(hex: "0E0809")
    static let huddleCard           = Color(hex: "2A1D1A")
    static let huddleSurface        = Color(hex: "1F1614")

    // MARK: - Legacy compat
    static let huddlePrimaryFixed   = Color(hex: "4A1E15")
    static let huddleSecondaryFixed = Color(hex: "3A2825")

    // MARK: - Typography
    static let huddleTextPrimary    = Color(hex: "F5E9E2")
    static let huddleTextSecondary  = Color(hex: "F5E9E2").opacity(0.72)
    static let huddleTextTertiary   = Color(hex: "F5E9E2").opacity(0.48)

    // MARK: - Borders
    static let huddleBorder         = Color(hex: "FFB496").opacity(0.10)
    static let huddleOutlineVariant = Color(hex: "FFB496").opacity(0.18)

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
