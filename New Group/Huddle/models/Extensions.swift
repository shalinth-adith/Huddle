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
    // Primary accent — coral orange (same in both modes)
    static let huddleCoral = Color(hex: "E86F51")

    // Page background
    static let huddleBackground = Color(UIColor { t in
        t.userInterfaceStyle == .dark ? UIColor(hex: "1C1C1E") : UIColor(hex: "F9F6F3")
    })

    // Card / sheet background (replaces hardcoded Color.white)
    static let huddleCard = Color(UIColor { t in
        t.userInterfaceStyle == .dark ? UIColor(hex: "2C2C2E") : .white
    })

    // Input field / light surface background
    static let huddleSurface = Color(UIColor { t in
        t.userInterfaceStyle == .dark ? UIColor(hex: "3A3A3C") : UIColor(hex: "F0F3FF")
    })

    // Icon container fills
    static let huddlePrimaryFixed = Color(UIColor { t in
        t.userInterfaceStyle == .dark ? UIColor(hex: "4A1E15") : UIColor(hex: "FFDAD2")
    })
    static let huddleSecondaryFixed = Color(UIColor { t in
        t.userInterfaceStyle == .dark ? UIColor(hex: "3A3A3C") : UIColor(hex: "E0E3E6")
    })

    // Typography
    static let huddleTextPrimary = Color(UIColor { t in
        t.userInterfaceStyle == .dark ? UIColor(hex: "F2F2F7") : UIColor(hex: "151C27")
    })
    static let huddleTextSecondary = Color(UIColor { t in
        t.userInterfaceStyle == .dark ? UIColor(hex: "ABABAB") : UIColor(hex: "57423D")
    })
    static let huddleTextTertiary = Color(UIColor { t in
        t.userInterfaceStyle == .dark ? UIColor(hex: "8E8E93") : UIColor(hex: "5F5E5C")
    })

    // Borders / dividers
    static let huddleBorder = Color(UIColor { t in
        t.userInterfaceStyle == .dark ? UIColor(hex: "38383A") : UIColor(hex: "E5E7EB")
    })
    static let huddleOutlineVariant = Color(UIColor { t in
        t.userInterfaceStyle == .dark ? UIColor(hex: "48302A") : UIColor(hex: "DEC0B9")
    })

    // Pinned card accent
    static let huddlePeach = Color(UIColor { t in
        t.userInterfaceStyle == .dark ? UIColor(hex: "3D2B00") : UIColor(hex: "FFD6A5")
    })

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
