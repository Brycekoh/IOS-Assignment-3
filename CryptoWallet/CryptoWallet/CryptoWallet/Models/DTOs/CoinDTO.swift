//
//  CoinDTO.swift
//  CryptoWallet
//
//  Codable structs that exactly mirror the CoinGecko JSON shapes.
//  These exist *only* to decode the wire format. They expose `toDomain()`
//  which converts to the clean app-facing types (`Coin`, `CoinDetail`).
//
//  Why this split:
//    • The API uses snake_case keys, optional fields, and presentation-
//      irrelevant nested junk (`platforms`, `categories`, etc.).
//    • If CoinGecko changes the API tomorrow, the only file that needs
//      updating is this one — the rest of the app keeps working.
//    • Tests can construct domain types directly without going through
//      JSON, because they're plain structs with public init.
//

import Foundation

// MARK: - /coins/markets

struct CoinDTO: Decodable {
    let id: String
    let symbol: String
    let name: String
    let image: String?
    let current_price: Double?
    let market_cap: Double?
    let market_cap_rank: Int?
    let price_change_24h: Double?
    let price_change_percentage_24h: Double?
    let sparkline_in_7d: SparklineDTO?
    
    struct SparklineDTO: Decodable {
        let price: [Double]?
    }
    
    func toDomain() -> Coin {
        Coin(
            id: id,
            symbol: symbol,
            name: name,
            imageURL: image.flatMap { URL(string: $0) },
            currentPrice: current_price ?? 0,
            marketCap: market_cap,
            marketCapRank: market_cap_rank,
            priceChange24h: price_change_24h,
            priceChangePercent24h: price_change_percentage_24h,
            sparkline: sparkline_in_7d?.price
        )
    }
}

// MARK: - /coins/{id}

struct CoinDetailDTO: Decodable {
    let id: String
    let symbol: String
    let name: String
    let description: LocalisedString?
    let image: ImageDTO?
    let links: LinksDTO?
    let market_data: MarketDataDTO?
    
    struct LocalisedString: Decodable {
        let en: String?
    }
    struct ImageDTO: Decodable {
        let large: String?
    }
    struct LinksDTO: Decodable {
        let homepage: [String]?
    }
    struct MarketDataDTO: Decodable {
        let current_price: [String: Double]?
        let market_cap: [String: Double]?
        let ath: [String: Double]?
        let atl: [String: Double]?
        let price_change_percentage_24h: Double?
    }
    
    // Currency-aware conversion: the same DTO can produce a CoinDetail
    // priced in USD, AUD, etc. depending on the active setting.
    func toDomain(currency: Currency) -> CoinDetail {
        let code = currency.apiCode
        return CoinDetail(
            id: id,
            symbol: symbol,
            name: name,
            imageURL: image?.large.flatMap { URL(string: $0) },
            descriptionHTML: description?.en ?? "",
            homepageURL: links?.homepage?.first.flatMap { URL(string: $0) },
            currentPrice: market_data?.current_price?[code] ?? 0,
            marketCap: market_data?.market_cap?[code],
            allTimeHigh: market_data?.ath?[code],
            allTimeLow: market_data?.atl?[code],
            priceChangePercent24h: market_data?.price_change_percentage_24h
        )
    }
}

// MARK: - /coins/{id}/market_chart

struct MarketChartDTO: Decodable {
    // CoinGecko returns [[timestamp_ms, price], …] — an array of two-element
    // arrays. We decode it as [[Double]] and pair them up in toDomain().
    let prices: [[Double]]
    
    func toDomain() -> [PricePoint] {
        prices.compactMap { pair in
            guard pair.count >= 2 else { return nil }
            let date = Date(timeIntervalSince1970: pair[0] / 1000)
            return PricePoint(date: date, price: pair[1])
        }
    }
}

// MARK: - /search

struct SearchResultDTO: Decodable {
    let coins: [SearchCoinDTO]
    
    struct SearchCoinDTO: Decodable {
        let id: String
        let name: String
        let symbol: String
        let large: String?
        let market_cap_rank: Int?
    }
}
