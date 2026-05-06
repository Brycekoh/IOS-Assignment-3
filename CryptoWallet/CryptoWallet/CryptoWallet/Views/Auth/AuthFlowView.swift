//
//  AuthFlowView.swift
//  CryptoWallet
//
//  Coordinator for the login/signup screens. Owns a NavigationStack
//  so push/pop transitions feel native, and takes a starting "step"
//  (login or signup) so the WelcomeView buttons pre-route the user
//  to the right form.
//

import SwiftUI

struct AuthFlowView: View {
    
    enum Step {
        case login
        case signup
    }
    
    let initialStep: Step
    
    var body: some View {
        NavigationStack {
            switch initialStep {
            case .login:  LoginView()
            case .signup: SignupView()
            }
        }
        .tint(Theme.accentYellow)
    }
}

#if DEBUG
#Preview("Login") {
    AuthFlowView(initialStep: .login)
        .environment(PreviewState.empty)
        .preferredColorScheme(.dark)
}

#Preview("Signup") {
    AuthFlowView(initialStep: .signup)
        .environment(PreviewState.empty)
        .preferredColorScheme(.dark)
}
#endif
