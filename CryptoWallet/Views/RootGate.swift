//
//  RootGate.swift
//  CryptoWallet
//
//  The single switch statement that drives top-level navigation. Looks
//  at:
//    1. Has the user seen the marketing onboarding? — if no, show it.
//    2. Is there an authenticated account? — if no, show Welcome → Auth.
//    3. Has the user verified email? — if no, show 4-digit code screen.
//    4. Has the user finished KYC? — if no, show KYC flow.
//    5. Otherwise — show the main tabbed app.
//
//  Centralising this here means individual views never have to ask
//  "should I be visible?". They just render. The gate is the single
//  source of truth for routing.
//

import SwiftUI

struct RootGate: View {
    
    @Environment(AppState.self) private var appState
    @AppStorage("onboarding.seen.v1") private var hasSeenOnboarding = false
    @State private var welcomeStep: WelcomeRoute = .welcome
    
    enum WelcomeRoute: Equatable {
        case welcome
        case auth(AuthFlowView.Step)
    }
    
    var body: some View {
        Group {
            if !hasSeenOnboarding {
                OnboardingView { hasSeenOnboarding = true }
                    .transition(.opacity)
            } else if appState.account == nil {
                welcomeOrAuth
                    .transition(.opacity)
            } else if appState.account?.kycStatus == .notStarted {
                NavigationStack {
                    EmailVerificationView()
                }
                .tint(Theme.accentYellow)
                .transition(.opacity)
            } else if appState.account?.kycStatus == .emailVerified
                   || appState.account?.kycStatus == .kycInProgress {
                KYCFlowView()
                    .transition(.opacity)
            } else {
                RootTabView()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: hasSeenOnboarding)
        .animation(.easeInOut(duration: 0.3), value: appState.account?.kycStatus)
        .animation(.easeInOut(duration: 0.3), value: appState.account == nil)
        .onChange(of: appState.account?.id) { _, newValue in
            if newValue == nil {
                welcomeStep = .welcome
            }
        }
        .preferredColorScheme(colourScheme)
    }
    
    @ViewBuilder
    private var welcomeOrAuth: some View {
        switch welcomeStep {
        case .welcome:
            WelcomeView(
                onSignUp: { welcomeStep = .auth(.signup) },
                onLogIn:  { welcomeStep = .auth(.login) }
            )
        case .auth(let step):
            AuthFlowView(
                initialStep: step,
                onBack: { welcomeStep = .welcome }
            )
        }
    }
    
    private var colourScheme: ColorScheme? {
        switch appState.colourScheme {
        case .system: return nil
        case .light:  return .light
        case .dark:   return .dark
        }
    }
}

#if DEBUG
#Preview("Onboarding (cold start)") {
    RootGate()
        .environment(PreviewState.empty)
        .environment(\.cryptoService, MockCryptoService())
}

#Preview("Verified user") {
    RootGate()
        .environment(PreviewState.populated)
        .environment(\.cryptoService, MockCryptoService())
}
#endif
