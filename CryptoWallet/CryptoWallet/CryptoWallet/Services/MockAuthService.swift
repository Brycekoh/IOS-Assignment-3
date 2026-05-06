//
//  MockAuthService.swift
//  CryptoWallet
//
//  In-memory stub for previews and unit tests. Same interface as
//  LocalAuthService, no UserDefaults touched. Tests can preset the
//  initial account state via the initialiser.
//

import Foundation

final class MockAuthService: AuthServiceProtocol, @unchecked Sendable {
    
    private var account: Account?
    var shouldFail: AuthError?
    
    init(account: Account? = nil) {
        self.account = account
    }
    
    func currentAccount() -> Account? { account }
    
    func signUp(email: String, password: String, acceptedTerms: Bool) async throws -> Account {
        if let error = shouldFail { throw error }
        let new = Account(email: email)
        account = new
        return new
    }
    
    func logIn(email: String, password: String) async throws -> Account {
        if let error = shouldFail { throw error }
        let new = Account(email: email, kycStatus: .verified)
        account = new
        return new
    }
    
    func verifyEmail(code: String) async throws {
        if let error = shouldFail { throw error }
        account?.kycStatus = .emailVerified
    }
    
    func updateKYCProfile(_ profile: KYCProfile) async throws {
        if let error = shouldFail { throw error }
        account?.profile = profile
        if account?.kycStatus == .emailVerified {
            account?.kycStatus = .kycInProgress
        }
    }
    
    func completeKYC() async throws {
        if let error = shouldFail { throw error }
        account?.kycStatus = .verified
    }
    
    func logOut() { account = nil }
}
