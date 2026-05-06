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
}

final class PortfolioStore: PortfolioStoreProtocol, @unchecked Sendable {
    
    private let defaults: UserDefaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    
    private enum Key {
        static let holdings = "wallet.holdings.v1"
        static let favourites = "wallet.favourites.v1"
    }
    
    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }
    
    // MARK: - Holdings
    
    // Returns [] on first launch or if decoding fails. Swallowing decode
    // failures is intentional: a corrupted defaults blob shouldn't crash
    // the app, and if the user had no holdings before, [] is correct.
    func loadHoldings() -> [Holding] {
        guard let data = defaults.data(forKey: Key.holdings) else { return [] }
        return (try? decoder.decode([Holding].self, from: data)) ?? []
    }
    
    func saveHoldings(_ holdings: [Holding]) {
        guard let data = try? encoder.encode(holdings) else { return }
        defaults.set(data, forKey: Key.holdings)
    }
    
    // MARK: - Favourites (set of coin ids)
    
    func loadFavourites() -> Set<String> {
        guard let data = defaults.data(forKey: Key.favourites) else { return [] }
        return (try? decoder.decode(Set<String>.self, from: data)) ?? []
    }
    
    func saveFavourites(_ favourites: Set<String>) {
        guard let data = try? encoder.encode(favourites) else { return }
        defaults.set(data, forKey: Key.favourites)
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
}
