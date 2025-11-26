//
//  Extensions.swift
//  Huddle
//
//  Created by shalinth adithyan on 26/11/25.
//

import Foundation
import SwiftUI

extension Color {
    static let huddleCoral = Color(hex : "FF9B85")
    static let huddlePeach = Color(hex : "FFD6A5")
    static let huddleBlue = Color(hex : "A8DADC")
    static let huddleBackground = Color(hex : "FFF8F3")
    
    init (hex: String) {
        let scanner = Scanner(string: hex)
        var rgbValue: UInt64 = 0
        scanner.scanHexInt64(&rgbValue)
        
        let r = Double((rgbValue & 0xFF0000) >> 16) / 255.0
                 let g = Double((rgbValue & 0x00FF00) >> 8) / 255.0
                 let b = Double(rgbValue & 0x0000FF) / 255.0

                 self.init(red: r, green: g, blue: b)

    }

}
