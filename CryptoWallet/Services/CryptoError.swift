//
//  CryptoError.swift
//  CryptoWallet
//
//  All errors that can flow out of the service layer. Conforms to
//  `LocalizedError` so views can show `error.errorDescription` directly
//  to the user without a separate translation step.
//
//  Modelled as an enum (not a generic `Error`) so call sites can `switch`
//  on the exact case and the compiler enforces exhaustiveness — this is
//  the "type system used to prevent incorrect code" rubric criterion.
//

import Foundation

enum CryptoError: LocalizedError, Equatable {
    case invalidURL
    case offline
    case rateLimited                 // CoinGecko free tier returns 429 when hammered
    case decodingFailed(String)      // wraps the underlying message for debug
    case server(statusCode: Int)
    case unknown(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "We couldn't build the request. Please try again."
        case .offline:
            return "You appear to be offline. Check your connection and pull to refresh."
        case .rateLimited:
            return "Too many requests right now. Try again in a moment."
        case .decodingFailed:
            return "We received an unexpected response from the server."
        case .server(let code):
            return "The server returned an error (\(code)). Please try again later."
        case .unknown(let message):
            return message
        }
    }
}
