//
//  PricePoint.swift
//  CryptoWallet
//
//  A single (timestamp, price) pair used by the historical chart.
//  Conforms to Identifiable so SwiftUI Charts can plot a series of them
//  without us having to manage indices manually.
//

import Foundation

struct PricePoint: Identifiable, Hashable {
    let id = UUID()
    let date: Date
    let price: Double
}

// Time ranges the user can select on the detail screen. Modelled as an
// enum (not raw integers) so the rest of the code uses semantically named
// values — no magic numbers like "30" floating around.
enum ChartRange: String, CaseIterable, Identifiable {
    case day = "1D"
    case week = "7D"
    case month = "30D"
    case year = "1Y"
    
    var id: String { rawValue }
    
    /// Display label shown on the segmented range picker. Same as raw
    /// value today, but kept as a separate property so we can localise
    /// it later without touching the rawValue contract.
    var label: String { rawValue }
    
    // Days passed to the CoinGecko market_chart endpoint.
    var days: Int {
        switch self {
        case .day: return 1
        case .week: return 7
        case .month: return 30
        case .year: return 365
        }
    }
}
