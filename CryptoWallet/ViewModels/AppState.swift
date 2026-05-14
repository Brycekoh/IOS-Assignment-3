//
//  AppState.swift
//  CryptoWallet
//
//  Single source of truth for app-wide state — the active currency,
//  the user's holdings, favourites, and the authenticated account.
//
//  Auth state is centralised here (not stuffed inside an auth-only
//  ViewModel) because so much of the rest of the app depends on it:
//  the root view picks which screen to show, the home view greets the
//  user by email, the settings screen offers logout. Putting all of
//  that behind one observable type keeps the wiring simple.
//

import Foundation
import Observation
import SwiftUI

@Observable
@MainActor
final class AppState {
    
    // MARK: - User-facing state
    
    var currency: Currency = .usd
    var colourScheme: AppColourScheme = .dark   // Foxcrypto is dark-first
    private(set) var holdings: [Holding] = []
    private(set) var favourites: Set<String> = []
    
    /// The currently authenticated account, if any. Drives the root
    /// navigation: nil → onboarding/auth, partial KYC → KYC flow,
    /// verified → main app.
    private(set) var account: Account?
    
    // MARK: - Dependencies (injected → loose coupling)
    
    private let store: PortfolioStoreProtocol
    private let authService: any AuthServiceProtocol
    
    init(
        store: PortfolioStoreProtocol = PortfolioStore(),
        authService: any AuthServiceProtocol = LocalAuthService()
    ) {
        self.store = store
        self.authService = authService
        self.currency = Self.loadCurrency()
        self.colourScheme = Self.loadColourScheme()
        self.account = authService.currentAccount()
        // Point the store at whoever's currently signed in BEFORE loading
        // holdings/favourites, so we read this account's namespaced data
        // and never another account's. On a fresh launch with no session,
        // account is nil and the store uses its "guest" namespace.
        store.setActiveAccount(account?.id.uuidString)
        self.holdings = store.loadHoldings()
        self.favourites = store.loadFavourites()
    }
    
    /// Re-point the store at the active account and reload its wallet.
    /// Called after every auth transition (sign up, log in, log out) so
    /// the in-memory holdings/favourites always match the signed-in user.
    private func reloadWalletForCurrentAccount() {
        store.setActiveAccount(account?.id.uuidString)
        holdings = store.loadHoldings()
        favourites = store.loadFavourites()
    }
    
    // MARK: - Auth surface
    //
    // The view layer doesn't talk to AuthService directly — everything
    // funnels through AppState so observable state updates atomically
    // when an auth action completes.
    
    func signUp(email: String, password: String, acceptedTerms: Bool) async throws {
        let new = try await authService.signUp(email: email, password: password, acceptedTerms: acceptedTerms)
        account = new
        // A brand-new account starts with an empty wallet — scoping the
        // store to its id ensures we don't inherit the previous user's
        // holdings that are still sitting in UserDefaults.
        reloadWalletForCurrentAccount()
    }
    
    func logIn(email: String, password: String) async throws {
        let signed = try await authService.logIn(email: email, password: password)
        account = signed
        // Load THIS account's saved holdings/favourites, not whatever
        // was last in memory from a previous session.
        reloadWalletForCurrentAccount()
    }
    
    func verifyEmail(code: String) async throws {
        try await authService.verifyEmail(code: code)
        account = authService.currentAccount()
    }
    
    func updateKYCProfile(_ profile: KYCProfile) async throws {
        try await authService.updateKYCProfile(profile)
        account = authService.currentAccount()
    }
    
    func completeKYC() async throws {
        try await authService.completeKYC()
        account = authService.currentAccount()
    }
    
    func logOut() {
        authService.logOut()
        account = nil
        // Clear the in-memory wallet and re-point the store at the
        // "guest" namespace. Without this, the signed-out state would
        // still hold the last user's holdings in memory — and the next
        // sign-up would briefly see them before its own reload.
        reloadWalletForCurrentAccount()
    }
    
    // MARK: - Holdings (wallet operations)
    
    func addHolding(_ holding: Holding) {
        holdings.append(holding)
        store.saveHoldings(holdings)
    }
    
    func removeHolding(id: UUID) {
        holdings.removeAll { $0.id == id }
        store.saveHoldings(holdings)
    }
    
    func removeHoldings(at offsets: IndexSet) {
        holdings.remove(atOffsets: offsets)
        store.saveHoldings(holdings)
    }
    
    // MARK: - Favourites
    
    func isFavourite(_ coinID: String) -> Bool {
        favourites.contains(coinID)
    }
    
    func toggleFavourite(_ coinID: String) {
        if favourites.contains(coinID) {
            favourites.remove(coinID)
        } else {
            favourites.insert(coinID)
        }
        store.saveFavourites(favourites)
    }
    
    // MARK: - Currency / theme persistence
    
    func setCurrency(_ new: Currency) {
        currency = new
        UserDefaults.standard.set(new.rawValue, forKey: "settings.currency")
    }
    
    func setColourScheme(_ new: AppColourScheme) {
        colourScheme = new
        UserDefaults.standard.set(new.rawValue, forKey: "settings.colourScheme")
    }
    
    /// The colour scheme as SwiftUI's `ColorScheme?` — nil means "follow
    /// the system". Used by the root view and by any sheet/cover that
    /// presents outside the root's environment and therefore has to
    /// re-apply the user's choice explicitly.
    var resolvedColorScheme: ColorScheme? {
        switch colourScheme {
        case .system: return nil
        case .light:  return .light
        case .dark:   return .dark
        }
    }
    
    private static func loadCurrency() -> Currency {
        guard let raw = UserDefaults.standard.string(forKey: "settings.currency"),
              let c = Currency(rawValue: raw) else { return .usd }
        return c
    }
    
    private static func loadColourScheme() -> AppColourScheme {
        guard let raw = UserDefaults.standard.string(forKey: "settings.colourScheme"),
              let c = AppColourScheme(rawValue: raw) else { return .dark }
        return c
    }
}

// MARK: - Colour scheme

enum AppColourScheme: String, CaseIterable, Identifiable {
    case system
    case light
    case dark
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .system: return "System"
        case .light:  return "Light"
        case .dark:   return "Dark"
        }
    }
}
