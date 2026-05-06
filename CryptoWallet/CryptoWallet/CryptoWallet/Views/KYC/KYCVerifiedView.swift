//
//  KYCVerifiedView.swift
//  CryptoWallet
//
//  Step 4 of KYC. Success screen with the "You're verified" headline
//  and a "Back to Home" CTA. Tapping the CTA simply marks the local
//  account as verified — RootGate observes that change and switches
//  to the main tabbed app automatically.
//

import SwiftUI

struct KYCVerifiedView: View {
    
    @Environment(AppState.self) private var appState
    @State private var hasFinished = false
    
    var body: some View {
        VStack(spacing: 0) {
            FoxcryptoNavBar(title: "")
            
            VStack(spacing: 16) {
                Spacer()
                
                ZStack {
                    if UIImage(named: "verified") != nil {
                        Image("verified")
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 220)
                    } else {
                        Image(systemName: "checkmark.shield.fill")
                            .font(.system(size: 120, weight: .light))
                            .foregroundStyle(Theme.accentYellow)
                            .scaleEffect(hasFinished ? 1 : 0.5)
                            .opacity(hasFinished ? 1 : 0)
                    }
                }
                
                Text("You're verified")
                    .font(AppFont.display(28))
                    .foregroundStyle(Theme.textPrimary)
                    .opacity(hasFinished ? 1 : 0)
                
                Text("You have been verified your information completely. Let's make transactions!")
                    .font(AppFont.body(14))
                    .foregroundStyle(Theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .opacity(hasFinished ? 1 : 0)
                
                Spacer()
                
                Button("Back to Home") {
                    Task {
                        Haptics.success()
                        try? await appState.completeKYC()
                    }
                }
                .buttonStyle(FoxcryptoButtonStyle())
                .padding(.horizontal, 24)
                .padding(.bottom, 16)
                .opacity(hasFinished ? 1 : 0)
            }
        }
        .task {
            // Brief celebratory beat: shield zooms in with a haptic,
            // then headline + body fade in. Better than instant render.
            try? await Task.sleep(nanoseconds: 200_000_000)
            Haptics.success()
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                hasFinished = true
            }
        }
    }
}
