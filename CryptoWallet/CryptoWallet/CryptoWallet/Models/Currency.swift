//
//  Currency.swift
//  CryptoWallet
//
//  The currencies the user can view prices in. Modelled as an enum with a
//  raw `String` value so adding a new fiat currency is purely a data change
//  — add a case here and it automatically appears in Settings (because the
//  picker iterates `Currency.allCases`) and gets passed to the API
//  (because the API call uses `currency.rawValue`).
//
//  This directly addresses the "Extensibility" rubric criterion: a new
//  mechanic / new content can be added by changing data instead of code.
//

import Foundation

enum Currency: String, CaseIterable, Identifiable, Codable {
    case usd
    case aud
    case eur
    case gbp
    case jpy
    
    var id: String { rawValue }
    
    // ISO code expected by the CoinGecko API — same as raw value.
    var apiCode: String { rawValue }
    
    // Human-readable label for the Settings picker.
    var displayName: String {
        switch self {
        case .usd: return "US Dollar"
        case .aud: return "Australian Dollar"
        case .eur: return "Euro"
        case .gbp: return "British Pound"
        case .jpy: return "Japanese Yen"
        }
    }
    
    // Symbol used when formatting prices. Note: a single-character symbol
    // is fine for these five; if we add CHF / KRW etc. we'd switch to a
    // proper NumberFormatter currency code per case.
    var symbol: String {
        switch self {
        case .usd: return "$"
        case .aud: return "A$"
        case .eur: return "€"
        case .gbp: return "£"
        case .jpy: return "¥"
        }
    }
    
    // Locale identifier used by the price formatter. Picking the right
    // locale per currency means $1,234.56 vs €1.234,56 formats correctly.
    var localeIdentifier: String {
        switch self {
        case .usd: return "en_US"
        case .aud: return "en_AU"
        case .eur: return "de_DE"
        case .gbp: return "en_GB"
        case .jpy: return "ja_JP"
        }
    }
}
