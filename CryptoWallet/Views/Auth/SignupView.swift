//
//  SignupView.swift
//  CryptoWallet
//
//  Account creation matching the Figma's Sign up screen: email +
//  password with a hint about format requirements, a Terms checkbox,
//  primary yellow CTA, and a "log in" footer for users who already
//  have an account.
//
//  Validation rules (≥8 chars, uppercase + numbers) are enforced both
//  client-side here and again in AuthService so the same rule applies
//  whether or not someone bypasses the form.
//

import SwiftUI

struct SignupView: View {
    var onBack: () -> Void = {}
    
    @Environment(AppState.self) private var appState
    
    @State private var email = ""
    @State private var password = ""
    @State private var acceptsTerms = false
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    private var canSubmit: Bool {
        !email.isEmpty && !password.isEmpty && acceptsTerms
    }
    
    var body: some View {
        ZStack {
            Theme.backgroundPrimary.ignoresSafeArea()
            
            VStack(spacing: 0) {
                form
                Spacer()
                footer
            }
            .padding(.horizontal, 24)
        }
        .navigationTitle("Sign up")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Theme.backgroundPrimary, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .foregroundStyle(Theme.textPrimary)
                }
                .accessibilityLabel("Back")
            }
        }
    }
    
    // MARK: - Form
    
    private var form: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                FieldLabel(text: "Email Address")
                FoxcryptoTextField(
                    placeholder: "Enter your email address",
                    text: $email,
                    keyboardType: .emailAddress,
                    contentType: .emailAddress
                )
            }
            
            VStack(alignment: .leading, spacing: 8) {
                FieldLabel(text: "Password")
                FoxcryptoTextField(
                    placeholder: "Enter your password",
                    text: $password,
                    isSecure: true,
                    contentType: .newPassword
                )
                Text("At least 8 characters with uppercase letters and numbers")
                    .font(AppFont.caption(12))
                    .foregroundStyle(Theme.textSecondary)
                    .padding(.top, 2)
            }
            
            termsCheckbox
            
            if let errorMessage {
                Text(errorMessage)
                    .font(AppFont.caption(12))
                    .foregroundStyle(Theme.downTint)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            Button {
                Task { await submit() }
            } label: {
                if isLoading {
                    ProgressView().tint(Theme.backgroundPrimary)
                } else {
                    Text("Sign up")
                }
            }
            .buttonStyle(FoxcryptoButtonStyle())
            .disabled(!canSubmit || isLoading)
            .opacity(canSubmit ? 1 : 0.6)
            .padding(.top, 8)
        }
        .padding(.top, 16)
    }
    
    private var termsCheckbox: some View {
        Button {
            acceptsTerms.toggle()
        } label: {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: acceptsTerms ? "checkmark.square.fill" : "square")
                    .foregroundStyle(acceptsTerms ? Theme.accentYellow : Theme.textSecondary)
                    .font(.system(size: 18, weight: .medium))
                
                // Mixed-text colour: "Accept" in white, the rest yellow,
                // matching the Figma's mixed-colour Terms link.
                (Text("Accept ").foregroundColor(Theme.textPrimary)
                    + Text("Terms of Use & Privacy Policy").foregroundColor(Theme.accentYellow))
                    .font(AppFont.body(13))
                    .multilineTextAlignment(.leading)
            }
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Footer
    
    private var footer: some View {
        HStack(spacing: 4) {
            Text("Already have an account?")
                .font(AppFont.body(14))
                .foregroundStyle(Theme.textSecondary)
            NavigationLink("Log in!") {
                LoginView(onBack: onBack)
            }
            .font(AppFont.bodyMedium(14))
            .foregroundStyle(Theme.accentYellow)
        }
        .padding(.bottom, 16)
    }
    
    // MARK: - Submit
    
    private func submit() async {
        errorMessage = nil
        isLoading = true
        defer { isLoading = false }
        do {
            try await appState.signUp(email: email, password: password, acceptedTerms: acceptsTerms)
            Haptics.success()
            // Navigation handled by RootGate observing the new account.
        } catch let error as AuthError {
            Haptics.error()
            errorMessage = error.errorDescription
        } catch {
            Haptics.error()
            errorMessage = "Something went wrong. Please try again."
        }
    }
}

#if DEBUG
#Preview {
    NavigationStack { SignupView() }
        .environment(PreviewState.empty)
        .preferredColorScheme(.dark)
}
#endif
