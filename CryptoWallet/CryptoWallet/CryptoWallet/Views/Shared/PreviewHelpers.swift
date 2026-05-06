//
//  PreviewHelpers.swift
//  CryptoWallet
//
//  Pre-populated AppState + service stubs for SwiftUI previews. Pulling
//  these into one file means every #Preview in the project gets a
//  consistent, demoable starting state without each preview having to
//  build its own.
//
//  Compiled out of release builds via DEBUG so previews never affect
//  app size or behaviour for end users.
//

#if DEBUG
import SwiftUI

enum PreviewState {
    
    /// AppState with no holdings, signed out — drops you onto onboarding.
    @MainActor
    static var empty: AppState {
        AppState(
            store: InMemoryPortfolioStore(),
            authService: MockAuthService()
        )
    }
    
    /// AppState with a verified user and three holdings — drops you
    /// straight into a populated main app.
    @MainActor
    static var populated: AppState {
        let holdings = [
            Holding(coinID: "bitcoin",  symbol: "btc", name: "Bitcoin",
                    quantity: 0.5,  purchasePrice: 45_000),
            Holding(coinID: "ethereum", symbol: "eth", name: "Ethereum",
                    quantity: 2.0,  purchasePrice: 3_200),
            Holding(coinID: "solana",   symbol: "sol", name: "Solana",
                    quantity: 25.0, purchasePrice: 120)
        ]
        let store = InMemoryPortfolioStore(
            holdings: holdings,
            favourites: ["bitcoin", "solana"]
        )
        let auth = MockAuthService(
            account: Account(email: "alex@example.com", kycStatus: .verified)
        )
        return AppState(store: store, authService: auth)
    }
    
    /// MarketViewModel pre-loaded with the mock sample coins so list
    /// previews don't show a permanent spinner.
    @MainActor
    static var loadedMarket: MarketViewModel {
        let vm = MarketViewModel()
        vm.coins = MockCryptoService.sampleCoins
        vm.phase = .loaded
        return vm
    }
}
#endif
