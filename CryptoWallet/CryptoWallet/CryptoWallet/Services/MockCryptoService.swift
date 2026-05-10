//
//  MockCryptoService.swift
//  CryptoWallet
//
//  In-memory stub used by SwiftUI previews and unit tests so we never
//  need a network during development. Conforming to the same protocol
//  as `CryptoService` is the whole point of having the protocol — this
//  file is the proof that the abstraction works.
//
//  Configurable failure mode (`shouldFail`) lets tests/previews verify
//  that the error UI states render correctly.
//

import Foundation

final class MockCryptoService: CryptoServiceProtocol, @unchecked Sendable {
    
    var shouldFail: CryptoError? = nil
    
    func fetchMarkets(currency: Currency, perPage: Int, page: Int) async throws -> [Coin] {
        if let error = shouldFail { throw error }
        // Tiny artificial delay so spinners are visible in previews.
        try? await Task.sleep(nanoseconds: 200_000_000)
        return Array(MockCryptoService.sampleCoins.prefix(perPage))
    }
    
    func fetchCoinDetail(id: String, currency: Currency) async throws -> CoinDetail {
        if let error = shouldFail { throw error }
        try? await Task.sleep(nanoseconds: 200_000_000)
        return CoinDetail(
            id: id,
            symbol: "btc",
            name: "Bitcoin",
            imageURL: nil,
            descriptionHTML: "Bitcoin is the first decentralized cryptocurrency. Nodes in the peer-to-peer bitcoin network verify transactions through cryptography and record them in a public distributed ledger called a blockchain.",
            homepageURL: URL(string: "https://bitcoin.org"),
            currentPrice: 67_432.10,
            marketCap: 1_320_000_000_000,
            allTimeHigh: 73_750.07,
            allTimeLow: 67.81,
            priceChangePercent24h: 2.34
        )
    }
    
    func fetchChart(id: String, currency: Currency, range: ChartRange) async throws -> [PricePoint] {
        if let error = shouldFail { throw error }
        try? await Task.sleep(nanoseconds: 200_000_000)
        // Synthesise a plausible-looking sine-wave price series so the
        // chart looks alive in previews.
        let now = Date()
        let count = max(24, range.days * 4)
        return (0..<count).map { i in
            let t = Double(i) / Double(count)
            let price = 65_000 + 5_000 * sin(t * .pi * 4) + Double.random(in: -500...500)
            let date = now.addingTimeInterval(-Double(count - i) * 3600)
            return PricePoint(date: date, price: price)
        }
    }
    
    func search(query: String) async throws -> [Coin] {
        if let error = shouldFail { throw error }
        let q = query.lowercased()
        return MockCryptoService.sampleCoins.filter {
            $0.name.lowercased().contains(q) || $0.symbol.lowercased().contains(q)
        }
    }
    
    // MARK: - Sample data
    
    static let sampleCoins: [Coin] = [
        makeCoin(
            id: "bitcoin",
            symbol: "btc",
            name: "Bitcoin",
            currentPrice: 67_432.10,
            marketCap: 1_320_000_000_000,
            marketCapRank: 1,
            priceChange24h: 1_532.40,
            priceChangePercent24h: 2.34,
            sparkline: sparkline48 { point in
                65_000 + point * 60 + sin(point / 3) * 800
            }
        ),
        makeCoin(
            id: "ethereum",
            symbol: "eth",
            name: "Ethereum",
            currentPrice: 3_521.55,
            marketCap: 423_000_000_000,
            marketCapRank: 2,
            priceChange24h: -45.20,
            priceChangePercent24h: -1.27,
            sparkline: sparkline48 { point in
                3_500 - sin(point / 4) * 80
            }
        ),
        makeCoin(
            id: "solana",
            symbol: "sol",
            name: "Solana",
            currentPrice: 178.32,
            marketCap: 82_000_000_000,
            marketCapRank: 5,
            priceChange24h: 7.10,
            priceChangePercent24h: 4.15,
            sparkline: sparkline48 { point in
                170 + sin(point / 2) * 6
            }
        ),
        makeCoin(
            id: "cardano",
            symbol: "ada",
            name: "Cardano",
            currentPrice: 0.52,
            marketCap: 18_500_000_000,
            marketCapRank: 9,
            priceChange24h: -0.01,
            priceChangePercent24h: -1.92,
            sparkline: sparkline48 { point in
                0.52 + sin(point / 4) * 0.02
            }
        ),
        makeCoin(
            id: "ripple",
            symbol: "xrp",
            name: "XRP",
            currentPrice: 0.61,
            marketCap: 33_000_000_000,
            marketCapRank: 7,
            priceChange24h: 0.02,
            priceChangePercent24h: 3.39,
            sparkline: sparkline48 { point in
                0.60 + sin(point / 3) * 0.015
            }
        )
    ]
    
    private static func makeCoin(
        id: String,
        symbol: String,
        name: String,
        currentPrice: Double,
        marketCap: Double,
        marketCapRank: Int,
        priceChange24h: Double,
        priceChangePercent24h: Double,
        sparkline: [Double]
    ) -> Coin {
        Coin(
            id: id,
            symbol: symbol,
            name: name,
            imageURL: nil,
            currentPrice: currentPrice,
            marketCap: marketCap,
            marketCapRank: marketCapRank,
            priceChange24h: priceChange24h,
            priceChangePercent24h: priceChangePercent24h,
            sparkline: sparkline
        )
    }
    
    private static func sparkline48(_ transform: (Double) -> Double) -> [Double] {
        (0..<48).map { transform(Double($0)) }
    }
}
