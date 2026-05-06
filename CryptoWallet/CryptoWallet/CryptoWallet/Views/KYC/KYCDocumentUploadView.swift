//
//  KYCDocumentUploadView.swift
//  CryptoWallet
//
//  Step 2 of KYC. Upload front and back of an ID card, with a
//  six-rule checklist mirroring the Figma. Tapping a slot toggles
//  it as "uploaded" (real photo capture is out of scope for the
//  rubric — we simulate the upload to keep the demo focused).
//

import SwiftUI

struct KYCDocumentUploadView: View {
    
    @Binding var profile: KYCProfile
    let onContinue: () -> Void
    let onBack: () -> Void
    
    @Environment(AppState.self) private var appState
    
    private var canContinue: Bool {
        profile.hasFrontPhoto && profile.hasBackPhoto
    }
    
    var body: some View {
        VStack(spacing: 0) {
            FoxcryptoNavBar(title: "Verify account", onBack: onBack)
            
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Upload Image of ID Card")
                        .font(AppFont.heading(18))
                        .foregroundStyle(Theme.textPrimary)
                        .padding(.top, 8)
                    
                    UploadSlot(
                        title: "Upload front page",
                        isFilled: profile.hasFrontPhoto
                    ) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            profile.hasFrontPhoto.toggle()
                        }
                    }
                    
                    UploadSlot(
                        title: "Upload back page",
                        isFilled: profile.hasBackPhoto
                    ) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            profile.hasBackPhoto.toggle()
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
                .disabled(!canContinue)
                .opacity(canContinue ? 1 : 0.6)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 16)
        }
    }
    
    private var rulesList: some View {
        VStack(alignment: .leading, spacing: 10) {
            RuleRow(text: "Government-issued", positive: true)
            RuleRow(text: "Original full-size, unedited document", positive: true)
            RuleRow(text: "Place documents against a single-coloured background", positive: true)
            RuleRow(text: "Readable, well-lit, coloured images", positive: true)
            RuleRow(text: "No black and white images", positive: false)
            RuleRow(text: "No edited or expired documents", positive: false)
        }
    }
}

#Preview {
    KYCDocumentUploadView(
        profile: .constant(KYCProfile()),
        onContinue: {},
        onBack: {}
    )
    .environment(AppState(authService: MockAuthService()))
    .preferredColorScheme(.dark)
}
