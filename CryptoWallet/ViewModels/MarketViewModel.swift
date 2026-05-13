//
//  MarketViewModel.swift
//  CryptoWallet
//
//  Drives the Market tab and the Top Coins section on Home. The same
//  instance is shared between both screens so loading happens once
//  and switching tabs is instant.
//
//  Pure SwiftUI/iOS-17 idiom:
//    - `@Observable` class, no `@Published`.
//    - Async methods called from `.task { }` in the view.
//    - Service injected per-call (not at init) so the same VM can be
//      shared across views that read service from the environment.
//

import Foundation
import Observation

@Observable
@MainActor
final class MarketViewModel {
    
    enum Phase: Equatable {
        case idle
        case loading
        case loaded
        case failed(CryptoError)
    }
    
    var coins: [Coin] = []
    var phase: Phase = .idle
    
    /// Fetch the first page of markets. Sets `.failed` rather than
    /// throwing so the view can render an error banner without
    /// try/catch in its body.
    func load(currency: Currency, service: any CryptoServiceProtocol) async {
        // Don't show a spinner on background refreshes if we already
        // have data — feels jankier than just updating in place.
        if coins.isEmpty {
            phase = .loading
        }
        
        do {
            let fresh = try await service.fetchMarkets(currency: currency, perPage: 50, page: 1)
            coins = fresh
            phase = .loaded
        } catch let error as CryptoError {
            phase = .failed(error)
        } catch {
            phase = .failed(.unknown(error.localizedDescription))
        }
    }
}
