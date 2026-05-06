//
//  EmailVerificationView.swift
//  CryptoWallet
//
//  Four-digit verification step matching the Figma. Each digit gets
//  its own bordered box; tapping any of them focuses the next empty
//  one. A 16-second resend countdown reflects the design spec.
//
//  Mock backend accepts any 4 numeric digits — the demo doesn't
//  require an actual code-delivery system.
//

import SwiftUI

struct EmailVerificationView: View {
    
    @Environment(AppState.self) private var appState
    
    @State private var digits: [String] = Array(repeating: "", count: 4)
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var resendSeconds = 16
    @State private var resendTimer: Timer?
    
    /// Single focus state across all four boxes — driven by the
    /// box index so we can move focus forward as digits are typed.
    @FocusState private var focusedField: Int?
    
    private var enteredCode: String { digits.joined() }
    private var canSubmit: Bool { enteredCode.count == 4 && enteredCode.allSatisfy(\.isNumber) }
    
    var body: some View {
        ZStack {
            Theme.backgroundPrimary.ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: 24) {
                description
                digitBoxes
                resendRow
                
                if let errorMessage {
                    Text(errorMessage)
                        .font(AppFont.caption(12))
                        .foregroundStyle(Theme.downTint)
                }
                
                Spacer()
                
                Button {
                    Task { await submit() }
                } label: {
                    if isLoading {
                        ProgressView().tint(Theme.backgroundPrimary)
                    } else {
                        Text("Verify")
                    }
                }
                .buttonStyle(FoxcryptoButtonStyle())
                .disabled(!canSubmit || isLoading)
                .opacity(canSubmit ? 1 : 0.6)
                .padding(.bottom, 16)
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)
        }
        .navigationTitle("Verification")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Theme.backgroundPrimary, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .onAppear { focusedField = 0; startResendCountdown() }
        .onDisappear { resendTimer?.invalidate() }
    }
    
    // MARK: - Pieces
    
    private var description: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Code have been sent to your email")
                .font(AppFont.body(14))
                .foregroundStyle(Theme.textSecondary)
            Text(appState.account?.email ?? "your inbox")
                .font(AppFont.bodyMedium(14))
                .foregroundStyle(Theme.textPrimary)
        }
        .padding(.top, 12)
    }
    
    private var digitBoxes: some View {
        HStack(spacing: 12) {
            ForEach(0..<4, id: \.self) { index in
                digitBox(at: index)
            }
        }
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .center)
    }
    
    private func digitBox(at index: Int) -> some View {
        TextField("", text: Binding(
            get: { digits[index] },
            set: { newValue in handleDigitInput(newValue, at: index) }
        ))
        .keyboardType(.numberPad)
        .multilineTextAlignment(.center)
        .font(AppFont.display(28))
        .foregroundStyle(Theme.textPrimary)
        .tint(Theme.accentYellow)
        .frame(width: 56, height: 64)
        .background(Theme.backgroundPrimary)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(
                    focusedField == index ? Theme.accentYellow : Theme.textSecondary.opacity(0.4),
                    lineWidth: 1.5
                )
        )
        .focused($focusedField, equals: index)
    }
    
    private var resendRow: some View {
        VStack(spacing: 4) {
            Text(timeString)
                .font(AppFont.captionBold(13))
                .foregroundStyle(Theme.textPrimary)
                .monospacedDigit()
            Button("Resend Code") { resetResendCountdown() }
                .font(AppFont.bodyMedium(14))
                .foregroundStyle(resendSeconds == 0 ? Theme.accentYellow : Theme.textSecondary)
                .disabled(resendSeconds > 0)
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Logic
    
    /// When a digit is typed: keep only the last numeric character
    /// (handles paste of multiple digits), advance focus, treat empty
    /// input as a backspace and move focus back.
    private func handleDigitInput(_ value: String, at index: Int) {
        let filtered = value.filter(\.isNumber)
        
        if filtered.isEmpty {
            digits[index] = ""
            if index > 0 { focusedField = index - 1 }
            return
        }
        
        digits[index] = String(filtered.suffix(1))
        if index < 3 {
            focusedField = index + 1
        } else {
            focusedField = nil
        }
    }
    
    private func submit() async {
        errorMessage = nil
        isLoading = true
        defer { isLoading = false }
        do {
            try await appState.verifyEmail(code: enteredCode)
            Haptics.success()
            // RootGate observes the kycStatus change and routes onward.
        } catch let error as AuthError {
            Haptics.error()
            errorMessage = error.errorDescription
        } catch {
            Haptics.error()
            errorMessage = "Something went wrong. Please try again."
        }
    }
    
    // MARK: - Resend countdown
    
    private var timeString: String {
        let m = resendSeconds / 60
        let s = resendSeconds % 60
        return String(format: "%02d : %02d", m, s)
    }
    
    private func startResendCountdown() {
        resendTimer?.invalidate()
        resendTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            Task { @MainActor in
                if resendSeconds > 0 {
                    resendSeconds -= 1
                } else {
                    resendTimer?.invalidate()
                }
            }
        }
    }
    
    private func resetResendCountdown() {
        resendSeconds = 16
        startResendCountdown()
    }
}

#if DEBUG
#Preview {
    let auth = MockAuthService(account: Account(email: "johny@gmail.com"))
    let state = AppState(store: InMemoryPortfolioStore(), authService: auth)
    return NavigationStack { EmailVerificationView() }
        .environment(state)
        .preferredColorScheme(.dark)
}
#endif
