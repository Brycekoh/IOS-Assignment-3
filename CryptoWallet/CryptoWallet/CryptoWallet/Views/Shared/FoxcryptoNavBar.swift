//
//  FoxcryptoNavBar.swift
//  CryptoWallet
//
//  Custom top bar for the KYC and post-auth flows where we don't
//  want SwiftUI's native NavigationStack chrome (different background
//  colour, different back button styling). Centres the title with a
//  back arrow on the left.
//
//  Used inside ZStacks rather than as a real NavigationStack because
//  the KYC flow is step-driven (state machine) rather than push-driven.
//

import SwiftUI

struct FoxcryptoNavBar: View {
    let title: String
    var onBack: (() -> Void)?
    
    var body: some View {
        ZStack {
            Text(title)
                .font(AppFont.heading(16))
                .foregroundStyle(Theme.textPrimary)
            
            HStack {
                if let onBack {
                    BackChevronButton(action: onBack)
                } else {
                    Color.clear.frame(width: 32, height: 32)
                }
                Spacer()
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Theme.backgroundPrimary)
    }
}
