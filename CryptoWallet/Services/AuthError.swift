//
//  AuthError.swift
//  CryptoWallet
//
//  Typed errors from the auth / KYC layer. Same pattern as `CryptoError`
//  in the data layer — exhaustive switches at call sites, user-facing
//  messages, no string-typed error handling.
//

import Foundation

enum AuthError: LocalizedError, Equatable {
    case invalidEmail
    case weakPassword
    case mustAcceptTerms
    case accountAlreadyExists
    case invalidCredentials
    case wrongVerificationCode
    case kycIncomplete
    case unknown(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidEmail:
            return "Please enter a valid email address."
        case .weakPassword:
            return "Password must be at least 8 characters with uppercase letters and numbers."
        case .mustAcceptTerms:
            return "You must accept the Terms of Use and Privacy Policy to continue."
        case .accountAlreadyExists:
            return "An account with this email already exists. Try logging in instead."
        case .invalidCredentials:
            return "We couldn't find an account with those credentials. Check and try again."
        case .wrongVerificationCode:
            return "That code doesn't match. Check your email and try again."
        case .kycIncomplete:
            return "Please complete identity verification to access this feature."
        case .unknown(let message):
            return message
        }
    }
}
