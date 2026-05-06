//
//  Haptics.swift
//  CryptoWallet
//
//  Tiny wrapper around UIKit's haptic feedback generators. Using these
//  on key user actions (verify success, holding saved, KYC complete)
//  makes the app feel more native than a typical SwiftUI demo.
//
//  All calls are fire-and-forget — no init, no setup, just a one-liner
//  in the action closure.
//

import UIKit

enum Haptics {
    
    /// Light "tap" feedback — for non-critical confirmations like
    /// adding an item to a list or toggling a favourite.
    static func light() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
    
    /// Medium tap — for primary actions like submitting a form.
    static func medium() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }
    
    /// "It worked" notification — for success states like KYC complete.
    static func success() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
    
    /// Error feedback — for invalid input or failed actions.
    static func error() {
        UINotificationFeedbackGenerator().notificationOccurred(.error)
    }
    
    /// Selection-changed feedback — for picker / segmented control taps.
    static func selection() {
        UISelectionFeedbackGenerator().selectionChanged()
    }
}
