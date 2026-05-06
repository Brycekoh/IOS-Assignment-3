//
//  CoinDetailViewModel.swift
//  CryptoWallet
//
//  Drives the Coin Detail screen. Fetches the coin's metadata and the
//  historical chart in parallel using `async let` — the canonical
//  Swift Concurrency way to run two independent fetches concurrently.
//
//  The view binds to `range` to switch between 1D/7D/30D/1Y; the view
//  model re-fetches the chart whenever it changes. A separate
//  `chartLoading` flag lets the view show a spinner over just the
//  chart while the rest of the screen stays put.
//

import Foundation
import Observation

@Observable
@MainActor
final class CoinDetailViewModel {
    
    var detail: CoinDetail?
    var chart: [PricePoint] = []
    var range: ChartRange = .week
    var chartLoading: Bool = false
    var error: CryptoError?
    
    /// Tracks the in-flight chart fetch so a rapid sequence of range
    /// changes cancels the previous fetch and only the latest one gets
    /// to write its result. Without this, a slow 1Y fetch could
    /// resolve *after* a fast 1D fetch and overwrite it with stale data.
    private var chartTask: Task<Void, Never>?
    
    /// First-load. Fetch metadata + initial chart in parallel.
    func load(coinID: String, currency: Currency, service: any CryptoServiceProtocol) async {
        chartLoading = true
        error = nil
        do {
            async let detailFetch = service.fetchCoinDetail(id: coinID, currency: currency)
            async let chartFetch  = service.fetchChart(id: coinID, currency: currency, range: range)
            
            let (detail, chart) = try await (detailFetch, chartFetch)
            self.detail = detail
            self.chart = chart
        } catch let error as CryptoError {
            self.error = error
        } catch {
            self.error = .unknown(error.localizedDescription)
        }
        chartLoading = false
    }
    
    /// User picked a different time range. Doesn't reset `detail`,
    /// only re-fetches the chart points. Cancels any prior in-flight
    /// fetch so we don't paint stale data.
    func changeRange(to new: ChartRange, coinID: String, service: any CryptoServiceProtocol) async {
        range = new
        chartTask?.cancel()
        chartLoading = true
        let task = Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                let fresh = try await service.fetchChart(id: coinID, currency: .usd, range: new)
                guard !Task.isCancelled else { return }
                self.chart = fresh
            } catch let error as CryptoError {
                if !Task.isCancelled { self.error = error }
            } catch {
                if !Task.isCancelled { self.error = .unknown(error.localizedDescription) }
            }
            self.chartLoading = false
        }
        chartTask = task
        await task.value
    }
}
