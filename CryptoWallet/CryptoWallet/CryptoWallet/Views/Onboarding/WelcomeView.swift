//
//  WelcomeView.swift
//  CryptoWallet
//
//  The "Fast And Flexible Trading" screen — paired Sign up / Log in
//  CTAs shown after onboarding when there's no authenticated account.
//

import SwiftUI

struct WelcomeView: View {
    let onSignUp: () -> Void
    let onLogIn: () -> Void
    
    var body: some View {
        ZStack {
            Theme.backgroundPrimary.ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: 24) {
                Spacer(minLength: 32)
                
                ZStack {
                    if UIImage(named: "welcome") != nil {
                        Image("welcome")
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 300)
                    } else {
                        Image(systemName: "iphone.gen3.radiowaves.left.and.right")
                            .font(.system(size: 140, weight: .light))
                            .foregroundStyle(Theme.accentYellow)
                            .padding(40)
                    }
                }
                .frame(maxWidth: .infinity)
                
                Spacer()
                
                Text("Fast And Flexible\nTrading")
                    .font(AppFont.display(34))
                    .foregroundStyle(Theme.textPrimary)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                HStack(spacing: 12) {
                    Button("Sign up", action: onSignUp)
                        .buttonStyle(FoxcryptoOutlineButtonStyle())
                    Button("Log in", action: onLogIn)
                        .buttonStyle(FoxcryptoButtonStyle())
                }
                .padding(.bottom, 12)
            }
            .padding(.horizontal, 24)
        }
    }
}

#Preview {
    WelcomeView(onSignUp: {}, onLogIn: {})
}
