//
//  LoginView.swift
//  CryptoWallet
//
//  Sign-in form matching the Figma's Log in screen: email + password
//  fields, Forgot password link, primary yellow CTA, and a "create an
//  account" footer that swaps to the signup screen.
//
//  Authentication runs through AppState (which proxies AuthService)
//  so the post-login state propagates everywhere automatically.
//

import SwiftUI

struct LoginView: View {
    var onBack: () -> Void = {}
    
    @Environment(AppState.self) private var appState
    
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    /// Disable the CTA until both fields have content. Server-side
    /// validation will catch malformed entries; this just stops users
    /// from tapping a button that can't possibly succeed yet.
    private var canSubmit: Bool {
        !email.isEmpty && !password.isEmpty
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
        .navigationTitle("Log in")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Theme.backgroundPrimary, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
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
                    contentType: .password
                )
                Button("Forgot password?") {
                    // Out of scope for this assignment — placeholder.
                }
                .font(AppFont.bodyMedium(13))
                .foregroundStyle(Theme.accentYellow)
                .padding(.top, 4)
            }
            
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
                    Text("Log in")
                }
            }
            .buttonStyle(FoxcryptoButtonStyle())
            .disabled(!canSubmit || isLoading)
            .opacity(canSubmit ? 1 : 0.6)
            .padding(.top, 16)
        }
        .padding(.top, 16)
    }
    
    // MARK: - Footer
    
    private var footer: some View {
        HStack(spacing: 4) {
            Text("New to Foxcrypto?")
                .font(AppFont.body(14))
                .foregroundStyle(Theme.textSecondary)
            NavigationLink("Create an account") {
                SignupView(onBack: onBack)
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
            try await appState.logIn(email: email, password: password)
            Haptics.success()
            // No manual navigation — RootGate observes appState.account
            // and switches the root view automatically once we're in.
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
    NavigationStack { LoginView() }
        .environment(PreviewState.empty)
        .preferredColorScheme(.dark)
}
#endif
