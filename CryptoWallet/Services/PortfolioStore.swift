//
//  PortfolioStore.swift
//  CryptoWallet
//
//  Persists the user's wallet (holdings) and favourites list using
//  `UserDefaults` + JSON encoding — exactly the persistence pattern
//  from BubblePop's HighScoreViewModel. UserDefaults is appropriate
//  here because the data is small (dozens of holdings at most) and
//  there's no querying / relational structure that would need Core Data.
//
//  Behind a protocol for the same loose-coupling reason as the API
//  service. Tests can inject an in-memory store; the production app
//  uses the UserDefaults-backed implementation.
//

import Foundation

protocol PortfolioStoreProtocol: Sendable {
    func loadHoldings() -> [Holding]
    func saveHoldings(_ holdings: [Holding])
    func loadFavourites() -> Set<String>
    func saveFavourites(_ favourites: Set<String>)
    /// Point the store at a specific account. All subsequent load/save
    /// calls read and write that account's namespaced keys. Passing nil
    /// (signed out) falls back to a shared "guest" namespace.
    func setActiveAccount(_ accountID: String?)
}

final class PortfolioStore: PortfolioStoreProtocol, @unchecked Sendable {
    
    private let defaults: UserDefaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    
    /// The account whose data we're currently reading/writing. When this
    /// changes, the computed keys change with it — so account A's
    /// holdings can never leak into account B's session.
    private var activeAccountID: String?
    
    // Base key names. The real storage key appends the account id so
    // every account has its own isolated slot, e.g.
    // "wallet.holdings.v1.<uuid>". Without the suffix, all accounts on
    // the device shared one blob — signing up as a new user showed the
    // previous user's coins.
    private enum Key {
        static let holdingsBase = "wallet.holdings.v1"
        static let favouritesBase = "wallet.favourites.v1"
    }
    
    private var holdingsKey: String {
        "\(Key.holdingsBase).\(activeAccountID ?? "guest")"
    }
    
    private var favouritesKey: String {
        "\(Key.favouritesBase).\(activeAccountID ?? "guest")"
    }
    
    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }
    
    func setActiveAccount(_ accountID: String?) {
        activeAccountID = accountID
    }
    
    // MARK: - Holdings
    
    // Returns [] on first launch or if decoding fails. Swallowing decode
    // failures is intentional: a corrupted defaults blob shouldn't crash
    // the app, and if the user had no holdings before, [] is correct.
    func loadHoldings() -> [Holding] {
        guard let data = defaults.data(forKey: holdingsKey) else { return [] }
        return (try? decoder.decode([Holding].self, from: data)) ?? []
    }
    
    func saveHoldings(_ holdings: [Holding]) {
        guard let data = try? encoder.encode(holdings) else { return }
        defaults.set(data, forKey: holdingsKey)
    }
    
    // MARK: - Favourites (set of coin ids)
    
    func loadFavourites() -> Set<String> {
        guard let data = defaults.data(forKey: favouritesKey) else { return [] }
        return (try? decoder.decode(Set<String>.self, from: data)) ?? []
    }
    
    func saveFavourites(_ favourites: Set<String>) {
        guard let data = try? encoder.encode(favourites) else { return }
        defaults.set(data, forKey: favouritesKey)
    }
}

// In-memory store for previews/tests. No file I/O, resets every launch.
final class InMemoryPortfolioStore: PortfolioStoreProtocol, @unchecked Sendable {
    private var holdings: [Holding] = []
    private var favourites: Set<String> = []
    
    init(holdings: [Holding] = [], favourites: Set<String> = []) {
        self.holdings = holdings
        self.favourites = favourites
    }
    
    func loadHoldings() -> [Holding] { holdings }
    func saveHoldings(_ holdings: [Holding]) { self.holdings = holdings }
    func loadFavourites() -> Set<String> { favourites }
    func saveFavourites(_ favourites: Set<String>) { self.favourites = favourites }
    // In-memory store is single-session, so account scoping is a no-op —
    // there's nothing persisted to leak between accounts.
    func setActiveAccount(_ accountID: String?) {}
}
