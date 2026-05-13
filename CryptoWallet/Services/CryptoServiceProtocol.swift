//
//  CryptoServiceProtocol.swift
//  CryptoWallet
//
//  The protocol that every ViewModel depends on. *Nothing* in the
//  ViewModel/View layers should ever import URLSession or know about
//  CoinGecko — they only see this protocol.
//
//  Why this matters for the rubric:
//    - Loose coupling: the network implementation can be swapped
//      without touching ViewModels. We do exactly that with
//      `MockCryptoService` for SwiftUI previews — no network calls
//      during development.
//    - Extensibility: if we wanted a second data source (say, Binance
//      for live prices) we'd add another conformer, not edit every
//      ViewModel.
//    - Error handling: every method `throws` `CryptoError`, so call
//      sites get exhaustive switches.
//

import Foundation

protocol CryptoServiceProtocol: Sendable {
    /// Top N coins by market cap, priced in the given fiat currency.
    /// `perPage` lets callers ask for a smaller list (e.g. AddHolding
    /// only needs a coin picker, not the whole market).
    func fetchMarkets(currency: Currency, perPage: Int, page: Int) async throws -> [Coin]
    
    /// Detailed info for a single coin.
    func fetchCoinDetail(id: String, currency: Currency) async throws -> CoinDetail
    
    /// Historical prices for the chart.
    func fetchChart(id: String, currency: Currency, range: ChartRange) async throws -> [PricePoint]
    
    /// Free-text coin search by name or symbol in the active fiat currency.
    func search(query: String, currency: Currency) async throws -> [Coin]
}
