//
//  Holding.swift
//  CryptoWallet
//
//  A single line in the user's wallet: how much of a given coin they hold
//  and what they paid for it. We persist the *coin id* plus quantities,
//  not a snapshot of the price — current value is computed at render time
//  by joining holdings with the latest market data.
//
//  This keeps the persisted model small, robust, and naturally up-to-date.
//  If we cached the price, the wallet would show stale numbers until the
//  user refreshed. Storing only `coinID` + quantity sidesteps that.
//

import Foundation

struct Holding: Identifiable, Hashable, Codable {
    let id: UUID                 // stable id so SwiftUI lists update cleanly
    let coinID: String           // CoinGecko slug, e.g. "bitcoin"
    let symbol: String           // cached so we can render even when offline
    let name: String             // ditto
    let quantity: Double         // amount held (e.g. 0.5 BTC)
    let purchasePrice: Double    // price per unit when bought (in USD)
    let purchaseDate: Date
    
    // Default initialiser used when the user adds a holding via the form.
    // `id` defaults to a fresh UUID so callers don't have to think about it.
    init(
        id: UUID = UUID(),
        coinID: String,
        symbol: String,
        name: String,
        quantity: Double,
        purchasePrice: Double,
        purchaseDate: Date = Date()
    ) {
        self.id = id
        self.coinID = coinID
        self.symbol = symbol
        self.name = name
        self.quantity = quantity
        self.purchasePrice = purchasePrice
        self.purchaseDate = purchaseDate
    }
    
    // Original cost basis in USD — used to colour profit/loss.
    var costBasisUSD: Double {
        quantity * purchasePrice
    }
}

// View-model concept: a holding joined with its current market price.
// Constructed at render time so the view never has to do the multiplication.
// Pure value type → trivially testable and threadsafe.
struct ValuedHolding: Identifiable, Hashable {
    let holding: Holding
    let currentPriceUSD: Double      // nil-safe: 0 means "no price yet"
    
    var id: UUID { holding.id }
    
    var currentValueUSD: Double {
        holding.quantity * currentPriceUSD
    }
    
    /// What the user originally spent on this holding — convenience
    /// for portfolio-level totals.
    var totalCostUSD: Double { holding.costBasisUSD }
    
    var profitLossUSD: Double {
        currentValueUSD - holding.costBasisUSD
    }
    
    // Percent change vs cost basis. Guarded against divide-by-zero so a
    // holding bought at price 0 (test data) doesn't produce NaN.
    var profitLossPercent: Double {
        guard holding.costBasisUSD > 0 else { return 0 }
        return (profitLossUSD / holding.costBasisUSD) * 100
    }
    
    var isProfit: Bool { profitLossUSD >= 0 }
}
