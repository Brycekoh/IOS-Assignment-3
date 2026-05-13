//
//  CryptoWalletApp.swift
//  CryptoWallet
//
//  App entry point. Builds the AppState (with persistent store +
//  local auth service) and injects it via the environment so every
//  child view can read/write app-wide state.
//
//  RootGate handles all top-level routing — onboarding, auth, KYC,
//  main app. This view itself is deliberately tiny.
//

import SwiftUI

@main
@MainActor
struct CryptoWalletApp: App {
    
    /// State + persistent store created once for the lifetime of the
    /// app. We construct it here so dependencies are injected (rather
    /// than auto-created inside AppState), which keeps tests honest.
    @State private var appState = AppState(
        store: PortfolioStore(),
        authService: LocalAuthService()
    )
    
    var body: some Scene {
        WindowGroup {
            RootGate()
                .environment(appState)
                .environment(\.cryptoService, CryptoService())
        }
    }
}
