//
//  Account.swift
//  CryptoWallet
//
//  The simulated user account. Persisted locally — there is no real
//  backend; this model exists so the auth/KYC flow has something
//  realistic to read and write.
//
//  The `KYCStatus` lifecycle drives navigation: a user lands on
//  onboarding → auth → KYC → home in that order, and we use this
//  status to decide which root screen to show.
//

import Foundation

struct Account: Codable, Equatable {
    let id: UUID
    let email: String
    let createdAt: Date
    var kycStatus: KYCStatus
    var profile: KYCProfile?
    
    init(
        id: UUID = UUID(),
        email: String,
        createdAt: Date = Date(),
        kycStatus: KYCStatus = .notStarted,
        profile: KYCProfile? = nil
    ) {
        self.id = id
        self.email = email
        self.createdAt = createdAt
        self.kycStatus = kycStatus
        self.profile = profile
    }
}

enum KYCStatus: String, Codable, Equatable {
    case notStarted          // just signed up, hasn't started KYC
    case emailVerified       // entered the email code, can use the app
    case kycInProgress       // partway through ID verification
    case verified            // fully verified
}

/// Snapshot of the data collected during KYC. Stored locally only —
/// in a real app this would be uploaded to a verification provider.
struct KYCProfile: Codable, Equatable {
    var country: String?
    var documentType: DocumentType?
    var hasFrontPhoto: Bool = false
    var hasBackPhoto: Bool = false
    var hasSelfiePhoto: Bool = false
    
    enum DocumentType: String, Codable, CaseIterable, Identifiable {
        case identifyCard = "Identify Card"  // (sic — matches Figma copy)
        case passport = "Passport"
        case driversLicense = "Driver's License"
        var id: String { rawValue }
        
        var iconName: String {
            switch self {
            case .identifyCard:    return "person.text.rectangle"
            case .passport:        return "book.closed"
            case .driversLicense:  return "car"
            }
        }
    }
}
