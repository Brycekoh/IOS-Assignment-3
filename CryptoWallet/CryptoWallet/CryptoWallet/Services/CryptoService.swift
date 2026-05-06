//
//  CryptoService.swift
//  CryptoWallet
//
//  The real network implementation that talks to CoinGecko's public API.
//  No API key required for the free tier.
//
//  Design notes:
//    - All methods are `async throws` (Swift Concurrency, replacing the
//      DispatchGroup / completion-handler patterns in the original
//      UIKit reference project).
//    - HTTP errors are translated into typed `CryptoError` cases so the
//      rest of the app never has to inspect URLError codes.
//    - Decoding goes through DTOs first, then `.toDomain()` produces the
//      clean app-facing types. This keeps API quirks out of the rest of
//      the app.
//

import Foundation

// `final` + `Sendable`: we want this safe to capture in @Observable
// view models without compiler warnings under strict concurrency.
final class CryptoService: CryptoServiceProtocol, Sendable {
    
    // Hardcoded base URL. We use a non-optional URL literal via the
    // iOS 16+ `URL(string:)` initialiser; if for some reason the
    // literal failed to parse, we'd crash on startup rather than
    // carrying an optional through every call site — but the literal
    // is known-good, so this is purely defensive code.
    private static let baseURL: URL = {
        guard let url = URL(string: "https://api.coingecko.com/api/v3") else {
            preconditionFailure("Invalid hardcoded base URL")
        }
        return url
    }()
    
    private let session: URLSession
    private let decoder: JSONDecoder
    
    init(session: URLSession = .shared) {
        self.session = session
        self.decoder = JSONDecoder()
    }
    
    // MARK: - Public API
    
    func fetchMarkets(currency: Currency, perPage: Int, page: Int) async throws -> [Coin] {
        let url = Self.baseURL
            .appending(path: "coins/markets")
            .appending(queryItems: [
                .init(name: "vs_currency", value: currency.apiCode),
                .init(name: "order", value: "market_cap_desc"),
                .init(name: "per_page", value: "\(perPage)"),
                .init(name: "page", value: "\(page)"),
                .init(name: "sparkline", value: "true"),
                .init(name: "price_change_percentage", value: "24h")
            ])
        
        let dtos: [CoinDTO] = try await get(url)
        return dtos.map { $0.toDomain() }
    }
    
    func fetchCoinDetail(id: String, currency: Currency) async throws -> CoinDetail {
        let url = Self.baseURL
            .appending(path: "coins/\(id)")
            .appending(queryItems: [
                .init(name: "localization", value: "false"),
                .init(name: "tickers", value: "false"),
                .init(name: "community_data", value: "false"),
                .init(name: "developer_data", value: "false")
            ])
        
        let dto: CoinDetailDTO = try await get(url)
        return dto.toDomain(currency: currency)
    }
    
    func fetchChart(id: String, currency: Currency, range: ChartRange) async throws -> [PricePoint] {
        let url = Self.baseURL
            .appending(path: "coins/\(id)/market_chart")
            .appending(queryItems: [
                .init(name: "vs_currency", value: currency.apiCode),
                .init(name: "days", value: "\(range.days)")
            ])
        
        let dto: MarketChartDTO = try await get(url)
        return dto.toDomain()
    }
    
    func search(query: String) async throws -> [Coin] {
        // The /search endpoint returns a slim response without prices, so
        // we then call /coins/markets with the resulting ids to get full
        // Coin objects. Two requests, but the user only sees one spinner.
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }
        
        let searchURL = Self.baseURL
            .appending(path: "search")
            .appending(queryItems: [.init(name: "query", value: trimmed)])
        
        let result: SearchResultDTO = try await get(searchURL)
        // Limit to top 20 to keep the second request small.
        let ids = result.coins.prefix(20).map(\.id)
        guard !ids.isEmpty else { return [] }
        
        let marketsURL = Self.baseURL
            .appending(path: "coins/markets")
            .appending(queryItems: [
                .init(name: "vs_currency", value: Currency.usd.apiCode),
                .init(name: "ids", value: ids.joined(separator: ",")),
                .init(name: "sparkline", value: "false")
            ])
        
        let dtos: [CoinDTO] = try await get(marketsURL)
        return dtos.map { $0.toDomain() }
    }
    
    // MARK: - Generic networking helper
    
    // Centralised request method. Every public method routes through here
    // so error translation, response-code handling, and decoding only
    // need to be correct in one place. Generic over `T: Decodable` so
    // the DTO type is inferred from the call site.
    private func get<T: Decodable>(_ url: URL) async throws -> T {
        let request = URLRequest(url: url, timeoutInterval: 20)
        
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch let urlError as URLError where urlError.code == .notConnectedToInternet {
            throw CryptoError.offline
        } catch let urlError as URLError {
            throw CryptoError.unknown(urlError.localizedDescription)
        } catch {
            throw CryptoError.unknown(error.localizedDescription)
        }
        
        // Translate HTTP status codes into typed errors. Switching on
        // exact codes is more useful than a single "non-200" catch-all.
        if let http = response as? HTTPURLResponse {
            switch http.statusCode {
            case 200..<300:
                break  // proceed to decode
            case 429:
                throw CryptoError.rateLimited
            default:
                throw CryptoError.server(statusCode: http.statusCode)
            }
        }
        
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw CryptoError.decodingFailed(error.localizedDescription)
        }
    }
}
