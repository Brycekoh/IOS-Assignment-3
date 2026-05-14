//
//  Theme.swift
//  CryptoWallet
//
//  Design tokens for the Foxcrypto visual system. Centralised so visual
//  changes happen in one file. Dark-mode hex codes lifted directly from
//  the Foxcrypto style guide (Nickelfox, Figma Community — credited in
//  README).
//
//  Each token is ADAPTIVE: it resolves to a dark value or a light value
//  depending on the active colour scheme. Because every view reads its
//  colours through these tokens, the whole app responds to the
//  light/dark setting in Settings without any per-view changes — the
//  adaptation happens here, once.
//
//  The yellow brand accent is deliberately the SAME in both modes — a
//  brand colour shouldn't shift with the theme.
//

import SwiftUI
import UIKit

enum Theme {
    
    // MARK: - Brand colours
    
    /// Primary canvas. Near-black in dark mode, near-white in light mode.
    static let backgroundPrimary = adaptive(dark: "16171D", light: "F4F5F7")
    
    /// Yellow accent — CTAs, highlights, brand mark. Constant across
    /// both modes: a brand colour shouldn't change with the theme.
    static let accentYellow = Color(hex: "F5C249")
    
    // MARK: - Base colours
    
    /// Second-level surface (cards). Dark grey in dark mode, white in
    /// light mode so cards lift off the background in both.
    static let surface = adaptive(dark: "21242D", light: "FFFFFF")
    
    /// Secondary text, placeholders, inactive icons. Mid grey that stays
    /// legible on both the dark and the light background.
    static let textSecondary = adaptive(dark: "A7AEBF", light: "6B7280")
    
    /// Primary text. Off-white on dark, near-black on light.
    static let textPrimary = adaptive(dark: "F8F8F8", light: "16171D")
    
    // MARK: - Derived / semantic
    
    /// Profit colour. Slightly deeper green in light mode so it keeps
    /// enough contrast against a white surface.
    static let upTint = adaptive(dark: "5BD68F", light: "1FA463")
    
    /// Loss colour. Deeper red in light mode for the same reason.
    static let downTint = adaptive(dark: "F26B6B", light: "D1453B")
    
    /// Gradient base for the Total Balance card. The card art reads well
    /// on both themes, so these stay constant.
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
    
    // MARK: - Adaptive colour builder
    
    /// Builds a Color that resolves to one hex in dark mode and another
    /// in light mode. Backed by UIColor's trait-aware initialiser, which
    /// SwiftUI re-resolves automatically whenever the colour scheme
    /// changes — so flipping the Settings toggle repaints every surface.
    private static func adaptive(dark: String, light: String) -> Color {
        Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .light
                ? UIColor(Color(hex: light))
                : UIColor(Color(hex: dark))
        })
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
