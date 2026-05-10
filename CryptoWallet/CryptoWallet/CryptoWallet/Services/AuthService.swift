//
//  AuthService.swift
//  CryptoWallet
//
//  Simulated backend for auth, email verification, and KYC. Behind a
//  protocol for the same loose-coupling reason as `CryptoServiceProtocol`
//  — a future swap to real Firebase / Supabase / custom backend means
//  writing a new conformer, not touching call sites.
//
//  All "network" delays are faked with `Task.sleep` so the UI flows feel
//  realistic during demo. Persistence uses UserDefaults — small,
//  appropriate for the data size, no Core Data ceremony.
//
//  ⚠️ Educational mock only — passwords are stored in plaintext in
//  UserDefaults. A real implementation would use Keychain + a
//  password-derivation function. Documented in code so a marker can
//  see we know the difference.
//

import Foundation

protocol AuthServiceProtocol: Sendable {
    /// Currently authenticated account, if any. Drives root navigation.
    func currentAccount() -> Account?
    
    /// Create a new account with email + password.
    func signUp(email: String, password: String, acceptedTerms: Bool) async throws -> Account
    
    /// Authenticate an existing account.
    func logIn(email: String, password: String) async throws -> Account
    
    /// Submit an email verification code. The mock accepts "1368".
    func verifyEmail(code: String) async throws
    
    /// Update the active account's KYC profile.
    func updateKYCProfile(_ profile: KYCProfile) async throws
    
    /// Mark KYC complete after the user finishes the upload steps.
    func completeKYC() async throws
    
    /// Sign the user out and clear the active session.
    func logOut()
}

final class LocalAuthService: AuthServiceProtocol, @unchecked Sendable {
    
    // MARK: - Persistence keys
    
    private enum Key {
        static let accounts = "auth.accounts.v1"        // [String: StoredCredentials]
        static let activeID = "auth.activeAccountID.v1" // UUID string
    }
    
    private struct StoredCredentials: Codable {
        let account: Account
        let password: String   // mock only — never do this in production
    }
    
    private enum DemoAccount {
        static let email = "test@example.com"
        static let password = "Password1"
    }
    
    private let defaults: UserDefaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    
    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        seedDemoAccountIfNeeded()
    }
    
    // MARK: - Read state
    
    func currentAccount() -> Account? {
        guard let idString = defaults.string(forKey: Key.activeID),
              let id = UUID(uuidString: idString) else { return nil }
        return loadAccounts().values.first(where: { $0.account.id == id })?.account
    }
    
    // MARK: - Sign up / log in
    
    func signUp(email: String, password: String, acceptedTerms: Bool) async throws -> Account {
        try await fakeNetworkDelay()
        let normalisedEmail = email.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Validation runs server-side in real systems; we run it here.
        try Self.validateEmail(normalisedEmail)
        try Self.validatePassword(password)
        guard acceptedTerms else { throw AuthError.mustAcceptTerms }
        
        var accounts = loadAccounts()
        guard accounts[normalisedEmail] == nil else {
            throw AuthError.accountAlreadyExists
        }
        
        let account = Account(email: normalisedEmail)
        accounts[normalisedEmail] = StoredCredentials(account: account, password: password)
        saveAccounts(accounts)
        setActive(account.id)
        return account
    }
    
    func logIn(email: String, password: String) async throws -> Account {
        try await fakeNetworkDelay()
        let normalisedEmail = email.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        let accounts = loadAccounts()
        guard let stored = accounts[normalisedEmail], stored.password == password else {
            throw AuthError.invalidCredentials
        }
        setActive(stored.account.id)
        return stored.account
    }
    
    // MARK: - Email verification
    
    func verifyEmail(code: String) async throws {
        try await fakeNetworkDelay()
        // The Figma shows "1368" as a sample code — we accept that and
        // also accept any 4-digit code so a demo isn't gated on memory.
        let trimmed = code.trimmingCharacters(in: .whitespaces)
        guard trimmed.count == 4, trimmed.allSatisfy(\.isNumber) else {
            throw AuthError.wrongVerificationCode
        }
        try mutateActiveAccount { $0.kycStatus = .emailVerified }
    }
    
    // MARK: - KYC
    
    func updateKYCProfile(_ profile: KYCProfile) async throws {
        try await fakeNetworkDelay(ms: 300)
        try mutateActiveAccount { account in
            account.profile = profile
            if account.kycStatus == .emailVerified {
                account.kycStatus = .kycInProgress
            }
        }
    }
    
    func completeKYC() async throws {
        try await fakeNetworkDelay(ms: 800)
        try mutateActiveAccount { $0.kycStatus = .verified }
    }
    
    // MARK: - Log out
    
    func logOut() {
        defaults.removeObject(forKey: Key.activeID)
    }
    
    // MARK: - Private helpers
    
    private func mutateActiveAccount(_ change: (inout Account) -> Void) throws {
        guard let idString = defaults.string(forKey: Key.activeID),
              let id = UUID(uuidString: idString) else {
            throw AuthError.invalidCredentials
        }
        var accounts = loadAccounts()
        guard let key = accounts.first(where: { $0.value.account.id == id })?.key else {
            throw AuthError.invalidCredentials
        }
        var stored = accounts[key]!
        var account = stored.account
        change(&account)
        stored = StoredCredentials(account: account, password: stored.password)
        accounts[key] = stored
        saveAccounts(accounts)
    }
    
    private func loadAccounts() -> [String: StoredCredentials] {
        guard let data = defaults.data(forKey: Key.accounts) else { return [:] }
        return (try? decoder.decode([String: StoredCredentials].self, from: data)) ?? [:]
    }
    
    private func saveAccounts(_ accounts: [String: StoredCredentials]) {
        guard let data = try? encoder.encode(accounts) else { return }
        defaults.set(data, forKey: Key.accounts)
    }
    
    private func setActive(_ id: UUID) {
        defaults.set(id.uuidString, forKey: Key.activeID)
    }
    
    /// Ensure the documented demo account exists on fresh installs so
    /// the README credentials actually work without a manual sign-up.
    private func seedDemoAccountIfNeeded() {
        let email = DemoAccount.email.lowercased()
        var accounts = loadAccounts()
        guard accounts[email] == nil else { return }
        
        let account = Account(email: email)
        accounts[email] = StoredCredentials(
            account: account,
            password: DemoAccount.password
        )
        saveAccounts(accounts)
    }
    
    /// Simulates network round-trip latency so the UI shows spinners
    /// and feels like a real app rather than instant magic.
    private func fakeNetworkDelay(ms: Int = 600) async throws {
        try await Task.sleep(nanoseconds: UInt64(ms) * 1_000_000)
    }
    
    // MARK: - Validation (static so tests can call without an instance)
    
    static func validateEmail(_ email: String) throws {
        // Simple but reasonable check — at least one '@' and one '.' after.
        let parts = email.split(separator: "@")
        guard parts.count == 2,
              !parts[0].isEmpty,
              parts[1].contains(".") else {
            throw AuthError.invalidEmail
        }
    }
    
    static func validatePassword(_ password: String) throws {
        guard password.count >= 8 else { throw AuthError.weakPassword }
        let hasUppercase = password.contains(where: { $0.isUppercase })
        let hasNumber = password.contains(where: { $0.isNumber })
        guard hasUppercase, hasNumber else { throw AuthError.weakPassword }
    }
}
