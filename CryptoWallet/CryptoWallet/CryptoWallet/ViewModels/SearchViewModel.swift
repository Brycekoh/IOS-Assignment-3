//
//  SearchViewModel.swift
//  CryptoWallet
//
//  Powers the search bar inside Market. Uses Swift Concurrency's
//  `Task` cancellation to debounce keystrokes — when the query
//  changes, we cancel any in-flight search and start a new one after
//  a short delay. Fast typing won't fire a request per character.
//
//  Service is injected per-call so the same VM can sit alongside the
//  shared MarketViewModel without a redundant init parameter.
//

import Foundation
import Observation

@Observable
@MainActor
final class SearchViewModel {
    
    enum Phase: Equatable {
        case idle
        case loading
        case loaded([Coin])
        case failed(CryptoError)
    }
    
    var phase: Phase = .idle
    
    private var searchTask: Task<Void, Never>?
    
    /// Trigger a new search. Debounces by 300ms — if the caller fires
    /// this multiple times in quick succession only the latest one
    /// will hit the network.
    func search(query: String, service: any CryptoServiceProtocol) {
        searchTask?.cancel()
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmed.isEmpty else {
            phase = .idle
            return
        }
        
        phase = .loading
        searchTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 300_000_000)
            guard !Task.isCancelled else { return }
            await self?.perform(query: trimmed, service: service)
        }
    }
    
    /// Wipe results — used when the search field is cleared.
    func clear() {
        searchTask?.cancel()
        phase = .idle
    }
    
    private func perform(query: String, service: any CryptoServiceProtocol) async {
        do {
            let results = try await service.search(query: query)
            guard !Task.isCancelled else { return }
            phase = .loaded(results)
        } catch let error as CryptoError {
            phase = .failed(error)
        } catch {
            phase = .failed(.unknown(error.localizedDescription))
        }
    }
}
