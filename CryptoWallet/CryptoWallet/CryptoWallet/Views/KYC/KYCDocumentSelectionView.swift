//
//  KYCDocumentSelectionView.swift
//  CryptoWallet
//
//  Step 1 of KYC. Pick a country of residence and a document type
//  (Identify Card / Passport / Driver's License). Each option is a
//  full-width card; the selected one gets the yellow accent border.
//
//  Countries come from the system's region list so the picker behaves
//  more like a real app, and the list expands inline instead of using
//  a Menu popover.
//

import SwiftUI

struct KYCDocumentSelectionView: View {
    
    @Binding var profile: KYCProfile
    let onContinue: () -> Void
    
    @Environment(AppState.self) private var appState
    @State private var isCountryListExpanded = false
    
    private let countries = Self.allCountries
    
    /// Continue is enabled only when both fields are filled — the
    /// server would reject incomplete submissions, but the UI shouldn't
    /// even let you submit them.
    private var canContinue: Bool {
        profile.country != nil && profile.documentType != nil
    }
    
    var body: some View {
        VStack(spacing: 0) {
            FoxcryptoNavBar(title: "Verify account")
            
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    countryPicker
                    documentTypePicker
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
            }
            
            VStack(spacing: 16) {
                KYCPrivacyNotice()
                Button("Continue") {
                    Task {
                        try? await appState.updateKYCProfile(profile)
                        onContinue()
                    }
                }
                .buttonStyle(FoxcryptoButtonStyle())
                .disabled(!canContinue)
                .opacity(canContinue ? 1 : 0.6)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 16)
        }
    }
    
    // MARK: - Country picker
    
    private var countryPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            FieldLabel(text: "Select Country of Resident")
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isCountryListExpanded.toggle()
                }
            } label: {
                HStack {
                    Text(profile.country ?? "Select country")
                        .font(AppFont.body(15))
                        .foregroundStyle(profile.country == nil ? Theme.textSecondary : Theme.textPrimary)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .foregroundStyle(Theme.textSecondary)
                        .font(.system(size: 12, weight: .semibold))
                        .rotationEffect(.degrees(isCountryListExpanded ? 180 : 0))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(Theme.surface)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .buttonStyle(.plain)

            countryList
        }
    }
    
    private var countryList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(countries, id: \.self) { country in
                    countryRow(country)
                }
            }
        }
        .frame(height: isCountryListExpanded ? 260 : 0)
        .opacity(isCountryListExpanded ? 1 : 0)
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Theme.textSecondary.opacity(isCountryListExpanded ? 0.18 : 0), lineWidth: 0.5)
        )
        .clipped()
        .allowsHitTesting(isCountryListExpanded)
        .animation(.easeInOut(duration: 0.24), value: isCountryListExpanded)
    }
    
    private func countryRow(_ country: String) -> some View {
        let isSelected = profile.country == country
        return Button {
            profile.country = country
            withAnimation(.easeInOut(duration: 0.2)) {
                isCountryListExpanded = false
            }
        } label: {
            HStack {
                Text(country)
                    .font(AppFont.body(14))
                    .foregroundStyle(isSelected ? Theme.accentYellow : Theme.textPrimary)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Theme.accentYellow)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(isSelected ? Theme.accentYellow.opacity(0.08) : Color.clear)
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Document type picker
    
    private var documentTypePicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            FieldLabel(text: "Select a valid Government-issued document")
            VStack(spacing: 12) {
                ForEach(KYCProfile.DocumentType.allCases) { type in
                    documentCard(type)
                }
            }
        }
    }
    
    private func documentCard(_ type: KYCProfile.DocumentType) -> some View {
        let isSelected = profile.documentType == type
        return Button {
            profile.documentType = type
        } label: {
            HStack(spacing: 12) {
                Image(systemName: type.iconName)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(isSelected ? Theme.accentYellow : Theme.textSecondary)
                Text(type.rawValue)
                    .font(AppFont.bodyMedium(15))
                    .foregroundStyle(isSelected ? Theme.accentYellow : Theme.textPrimary)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .background(Theme.surface)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(
                        isSelected ? Theme.accentYellow : Color.clear,
                        lineWidth: 1.5
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
    }
}

private extension KYCDocumentSelectionView {
    static var allCountries: [String] {
        let locale = Locale.autoupdatingCurrent
        return Locale.Region.isoRegions
            .compactMap { locale.localizedString(forRegionCode: $0.identifier) }
            .filter { !$0.isEmpty }
            .sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
    }
}

#Preview {
    KYCDocumentSelectionView(profile: .constant(KYCProfile()), onContinue: {})
        .environment(AppState(authService: MockAuthService()))
        .preferredColorScheme(.dark)
}
