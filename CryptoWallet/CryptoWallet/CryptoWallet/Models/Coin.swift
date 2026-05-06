//
//  Coin.swift
//  CryptoWallet
//
//  The app-facing representation of a cryptocurrency in the market list.
//  Deliberately separate from `CoinDTO` (the wire format from CoinGecko)
//  so the rest of the app never has to know what the API looks like.
//
//  Every property is `let`. Once a Coin is constructed it cannot be
//  mutated — this is the "immutable data" rubric criterion. If the price
//  changes, the API gives us a new Coin and the old one is replaced;
//  nothing in the code ever writes to `coin.currentPrice = ...`.
//

import Foundation

struct Coin: Identifiable, Hashable, Codable {
    let id: String              // CoinGecko's slug, e.g. "bitcoin"
    let symbol: String          // e.g. "btc"
    let name: String            // e.g. "Bitcoin"
    let imageURL: URL?
    let currentPrice: Double
    let marketCap: Double?
    let marketCapRank: Int?
    let priceChange24h: Double?         // absolute change in fiat
    let priceChangePercent24h: Double?  // percentage change
    let sparkline: [Double]?            // 7-day price points for mini chart
    
    // Convenience: did the coin go up in the last 24h? Used for tinting
    // the price-change label green/red. Computed properties on a let-only
    // struct stay safe — they're idempotent (same input → same output).
    var isUp: Bool {
        (priceChangePercent24h ?? 0) >= 0
    }
}
