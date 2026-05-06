//
//  Theme.swift
//  CryptoWallet
//
//  Design tokens for the Foxcrypto visual system. Centralised so visual
//  changes happen in one file. Hex codes lifted directly from the
//  Foxcrypto style guide (Nickelfox, Figma Community — credited in README).
//

import SwiftUI

enum Theme {
    
    // MARK: - Brand colours (from style guide)
    
    /// Near-black background — primary canvas across the app.
    static let backgroundPrimary = Color(hex: "16171D")
    
    /// Yellow accent — CTAs, highlights, brand mark.
    static let accentYellow = Color(hex: "F5C249")
    
    // MARK: - Base colours (from style guide)
    
    /// Dark grey card background — second-level surface.
    static let surface = Color(hex: "21242D")
    
    /// Mid grey — secondary text, placeholders, inactive icons.
    static let textSecondary = Color(hex: "A7AEBF")
    
    /// Off-white — primary text on dark surfaces.
    static let textPrimary = Color(hex: "F8F8F8")
    
    // MARK: - Derived / semantic
    
    /// Profit colour. Bright green for visibility on dark bg.
    static let upTint = Color(hex: "5BD68F")
    
    /// Loss colour.
    static let downTint = Color(hex: "F26B6B")
    
    /// Gradient base for the Total Balance card.
    static let balanceCardTop = Color(hex: "9DB7E8")
    static let balanceCardBottom = Color(hex: "C8D4E8")
    
    // MARK: - Layout tokens
    
    static let cornerRadius: CGFloat = 16
    static let cornerRadiusLarge: CGFloat = 20
    static let cardPadding: CGFloat = 16
    
    // MARK: - Convenience
    
    /// Profit/loss colour helper — green for >= 0, red for negative.
    static func plColour(_ value: Double) -> Color {
        value >= 0 ? upTint : downTint
    }
}

// MARK: - Color hex initialiser

extension Color {
    /// Build a Color from a hex string like "F5C249" or "#F5C249".
    /// Keeps designer/developer language identical and avoids the
    /// error-prone `Color(red: 0.96, green: 0.76, blue: 0.29)` route.
    init(hex: String) {
        let trimmed = hex.trimmingCharacters(in: .alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: trimmed).scanHexInt64(&int)
        let r, g, b, a: UInt64
        switch trimmed.count {
        case 3:  // RGB shorthand
            (r, g, b, a) = ((int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17, 255)
        case 6:  // RRGGBB
            (r, g, b, a) = (int >> 16, int >> 8 & 0xFF, int & 0xFF, 255)
        case 8:  // AARRGGBB
            (r, g, b, a) = (int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF, int >> 24)
        default:
            (r, g, b, a) = (255, 0, 255, 255)  // hot pink → "you have a typo"
        }
        self.init(
            .sRGB,
            red:   Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
