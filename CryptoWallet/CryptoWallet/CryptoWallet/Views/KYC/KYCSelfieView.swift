//
//  KYCSelfieView.swift
//  CryptoWallet
//
//  Step 3 of KYC. Single selfie upload with a four-rule checklist.
//  Uses the same shared components as the document step so the
//  visual language is consistent.
//

import SwiftUI

struct KYCSelfieView: View {
    
    @Binding var profile: KYCProfile
    let onContinue: () -> Void
    let onBack: () -> Void
    
    @Environment(AppState.self) private var appState
    
    var body: some View {
        VStack(spacing: 0) {
            FoxcryptoNavBar(title: "Verify account", onBack: onBack)
            
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Take Selfie Photo")
                        .font(AppFont.heading(18))
                        .foregroundStyle(Theme.textPrimary)
                        .padding(.top, 8)
                    
                    UploadSlot(
                        title: "Upload portrait photo",
                        isFilled: profile.hasSelfiePhoto
                    ) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            profile.hasSelfiePhoto.toggle()
                        }
                    }
                    
                    rulesList
                        .padding(.top, 16)
                }
                .padding(.horizontal, 24)
            }
            
            VStack(spacing: 16) {
                KYCPrivacyNotice()
                Button("Continue") {
                    Task {
                        try? await appState.updateKYCProfile(profile)
                        onContinue()
                    }
                }
                .buttonStyle(FoxcryptoButtonStyle())
                .disabled(!profile.hasSelfiePhoto)
                .opacity(profile.hasSelfiePhoto ? 1 : 0.6)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 16)
        }
    }
    
    private var rulesList: some View {
        VStack(alignment: .leading, spacing: 10) {
            RuleRow(text: "Take a selfie of yourself with a neutral expression", positive: true)
            RuleRow(text: "Make sure your whole face is visible, centred, and your eyes are open", positive: true)
            RuleRow(text: "Do not crop your ID or screenshots of your ID", positive: false)
            RuleRow(text: "Do not hide or alter parts of your face (No hats / beauty images / filters / headgear)", positive: false)
        }
    }
}

#Preview {
    KYCSelfieView(
        profile: .constant(KYCProfile()),
        onContinue: {},
        onBack: {}
    )
    .environment(AppState(authService: MockAuthService()))
    .preferredColorScheme(.dark)
}
