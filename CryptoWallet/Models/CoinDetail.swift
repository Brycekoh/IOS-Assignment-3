//
//  CoinDetail.swift
//  CryptoWallet
//
//  Richer info shown on the detail screen — description, all-time high,
//  links, etc. Kept separate from `Coin` because (a) the market-list
//  endpoint doesn't return any of these fields, and (b) detail data is
//  fetched lazily, only when the user opens a coin.
//

import Foundation

struct CoinDetail: Identifiable, Hashable {
    let id: String
    let symbol: String
    let name: String
    let imageURL: URL?
    let descriptionHTML: String      // CoinGecko returns description with <a> tags etc.
    let homepageURL: URL?
    let currentPrice: Double
    let marketCap: Double?
    let allTimeHigh: Double?
    let allTimeLow: Double?
    let priceChangePercent24h: Double?
    
    // Plain-text version of the description. Stripping tags here means the
    // view layer never has to know HTML exists — separation of concerns.
    var descriptionPlain: String {
        descriptionHTML
            .replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
