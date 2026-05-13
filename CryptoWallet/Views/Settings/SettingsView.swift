//
//  SettingsView.swift
//  CryptoWallet
//
//  Settings tab. Account info card with KYC status, currency picker,
//  appearance picker, wallet stats, about with credits, logout.
//
//  All persistence is delegated to AppState — this view is purely a
//  styled face on top.
//

import SwiftUI

struct SettingsView: View {
    
    @Environment(AppState.self) private var appState
    @State private var showLogoutPrompt = false
    
    var showsCloseButton: Bool = false
    var onClose: (() -> Void)? = nil
    
    var body: some View {
        ZStack {
            Theme.backgroundPrimary.ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    header
                    accountCard
                    sectionTitle("Preferences")
                    currencyPicker
                    appearancePicker
                    sectionTitle("Wallet")
                    walletStats
                    sectionTitle("About")
                    aboutCard
                    sectionTitle("Account")
                    logoutButton
                    Color.clear.frame(height: 80)
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
            }
            
            if showLogoutPrompt {
                logoutPromptOverlay
            }
        }
    }
    
    // MARK: - Header
    
    private var header: some View {
        HStack {
            Text("Settings")
                .font(AppFont.display(28))
                .foregroundStyle(Theme.textPrimary)
            Spacer()
            if showsCloseButton {
                Button {
                    onClose?()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Theme.textPrimary)
                        .frame(width: 32, height: 32)
                        .background(Theme.surface)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.top, 8)
    }
    
    // MARK: - Account card
    
    private var accountCard: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Theme.accentYellow.opacity(0.18))
                    .frame(width: 48, height: 48)
                Image(systemName: "person.fill")
                    .foregroundStyle(Theme.accentYellow)
                    .font(.system(size: 20))
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(appState.account?.email ?? "Guest")
                    .font(AppFont.bodyMedium(14))
                    .foregroundStyle(Theme.textPrimary)
                    .lineLimit(1)
                Text(kycLabel)
                    .font(AppFont.caption(11))
                    .foregroundStyle(kycTint)
            }
            Spacer()
        }
        .padding(14)
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius))
    }
    
    private var kycLabel: String {
        switch appState.account?.kycStatus {
        case .verified:        return "Verified"
        case .kycInProgress:   return "Verification pending"
        case .emailVerified:   return "Email verified"
        case .notStarted, nil: return "Not verified"
        }
    }
    
    private var kycTint: Color {
        switch appState.account?.kycStatus {
        case .verified:                              return Theme.upTint
        case .kycInProgress, .emailVerified:         return Theme.accentYellow
        case .notStarted, nil:                       return Theme.textSecondary
        }
    }
    
    // MARK: - Section title
    
    private func sectionTitle(_ title: String) -> some View {
        Text(title.uppercased())
            .font(AppFont.captionBold(11))
            .foregroundStyle(Theme.textSecondary)
            .padding(.top, 8)
            .padding(.horizontal, 4)
    }
    
    // MARK: - Currency picker
    
    private var currencyPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(Currency.allCases) { currency in
                Button {
                    appState.setCurrency(currency)
                } label: {
                    HStack {
                        Text(currency.displayName)
                            .font(AppFont.body(14))
                            .foregroundStyle(Theme.textPrimary)
                        Spacer()
                        if appState.currency == currency {
                            Image(systemName: "checkmark")
                                .foregroundStyle(Theme.accentYellow)
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(Theme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    // MARK: - Appearance picker
    
    private var appearancePicker: some View {
        HStack(spacing: 4) {
            ForEach(AppColourScheme.allCases) { scheme in
                Button {
                    appState.setColourScheme(scheme)
                } label: {
                    Text(scheme.displayName)
                        .font(AppFont.bodyMedium(13))
                        .foregroundStyle(appState.colourScheme == scheme ? Theme.backgroundPrimary : Theme.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(appState.colourScheme == scheme ? Theme.accentYellow : Color.clear)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
        }
        .padding(4)
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
    
    // MARK: - Wallet stats
    
    private var walletStats: some View {
        VStack(spacing: 0) {
            statRow(label: "Holdings", value: "\(appState.holdings.count)")
            divider
            statRow(label: "Favourites", value: "\(appState.favourites.count)")
        }
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius))
    }
    
    private func statRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(AppFont.body(14))
                .foregroundStyle(Theme.textPrimary)
            Spacer()
            Text(value)
                .font(AppFont.mono(14, weight: .semibold))
                .foregroundStyle(Theme.textSecondary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }
    
    private var divider: some View {
        Rectangle()
            .fill(Theme.textSecondary.opacity(0.15))
            .frame(height: 0.5)
            .padding(.horizontal, 14)
    }
    
    // MARK: - About card
    
    private var aboutCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("CryptoWallet")
                .font(AppFont.bodyMedium(14))
                .foregroundStyle(Theme.textPrimary)
            Text("UTS Mobile App Development assignment, built with SwiftUI and the CoinGecko public API. UI design inspired by the Foxcrypto community template by Nickelfox (used with credit).")
                .font(AppFont.caption(12))
                .foregroundStyle(Theme.textSecondary)
        }
        .padding(14)
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius))
    }
    
    // MARK: - Logout
    
    private var logoutButton: some View {
        Button(role: .destructive) {
            withAnimation(.easeInOut(duration: 0.2)) {
                showLogoutPrompt = true
            }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                    .font(.system(size: 18, weight: .semibold))
                    .frame(width: 22)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Log out")
                        .font(AppFont.bodyMedium(15))
                    Text("Return to the welcome screen")
                        .font(AppFont.caption(11))
                        .foregroundStyle(Theme.downTint.opacity(0.78))
                }
                Spacer()
            }
            .foregroundStyle(Theme.downTint)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Theme.downTint.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Theme.downTint, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var logoutPromptOverlay: some View {
        ZStack {
            VStack {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Log out?")
                        .font(AppFont.heading(20))
                        .foregroundStyle(Theme.textPrimary)
                    
                    Text("Your local holdings stay on this device. You'll need to log back in to use the app.")
                        .font(AppFont.body(14))
                        .foregroundStyle(Theme.textSecondary)
                    
                    HStack(spacing: 10) {
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                showLogoutPrompt = false
                            }
                        } label: {
                            Text("Cancel")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(FoxcryptoOutlineButtonStyle())
                        
                        Button {
                            showLogoutPrompt = false
                            appState.logOut()
                        } label: {
                            Text("Log out")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(FoxcryptoButtonStyle())
                    }
                }
                .padding(20)
                .frame(maxWidth: 340)
                .background(Theme.surface)
                .clipShape(RoundedRectangle(cornerRadius: 18))
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(Theme.textSecondary.opacity(0.14), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.28), radius: 18, y: 10)
            }
            .padding(.horizontal, 24)
            .transition(.scale(scale: 0.96).combined(with: .opacity))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        SettingsView()
    }
    .environment(PreviewState.populated)
    .preferredColorScheme(.dark)
}
#endif
