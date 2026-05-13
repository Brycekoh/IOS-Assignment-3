//
//  AppFont.swift
//  CryptoWallet
//
//  Centralised typography. We use SF Pro Rounded as a free, native
//  alternative to the Foxcrypto design's Poppins. SF Pro Rounded has
//  similar geometric proportions and ships with iOS — no font bundling,
//  no Info.plist edits, no risk of the project failing to open.
//
//  Style guide weights (Regular/Medium/Semibold/Bold) map cleanly to
//  SF Pro's weights. Adopting `font-design: .rounded` gives us the
//  approachable, modern feel of Poppins.
//
//  Replacing the font later (e.g. with real Poppins .ttfs) is a one-file
//  change: swap the `Font.system(...)` calls below for `Font.custom(...)`.
//

import SwiftUI

enum AppFont {
    
    /// Display heading — used for screen titles and the Total Balance number.
    static func display(_ size: CGFloat = 28) -> Font {
        .system(size: size, weight: .bold, design: .rounded)
    }
    
    /// Section/card heading — used for "Top Coins", "News", section titles.
    static func heading(_ size: CGFloat = 18) -> Font {
        .system(size: size, weight: .semibold, design: .rounded)
    }
    
    /// Standard body text.
    static func body(_ size: CGFloat = 15) -> Font {
        .system(size: size, weight: .regular, design: .rounded)
    }
    
    /// Emphasised body — labels, button text.
    static func bodyMedium(_ size: CGFloat = 15) -> Font {
        .system(size: size, weight: .medium, design: .rounded)
    }
    
    /// Caption — secondary text, hints.
    static func caption(_ size: CGFloat = 12) -> Font {
        .system(size: size, weight: .regular, design: .rounded)
    }
    
    /// Caption bold — small labels and section headers.
    static func captionBold(_ size: CGFloat = 12) -> Font {
        .system(size: size, weight: .semibold, design: .rounded)
    }
    
    /// Mono variant for monetary values / numeric displays.
    /// Tabular figures means digits don't shift width — important for
    /// numbers like "$1,234" updating in place.
    static func mono(_ size: CGFloat = 15, weight: Font.Weight = .semibold) -> Font {
        .system(size: size, weight: weight, design: .rounded).monospacedDigit()
    }
}
