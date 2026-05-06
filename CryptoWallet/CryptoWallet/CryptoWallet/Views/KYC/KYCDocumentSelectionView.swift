//
//  KYCDocumentSelectionView.swift
//  CryptoWallet
//
//  Step 1 of KYC. Pick a country of residence and a document type
//  (Identify Card / Passport / Driver's License). Each option is a
//  full-width card; the selected one gets the yellow accent border.
//
//  We use a static country list — sufficient for the demo. A real
//  app would pull this from a localised list or geolocation service.
//

import SwiftUI

struct KYCDocumentSelectionView: View {
    
    @Binding var profile: KYCProfile
    let onContinue: () -> Void
    
    @Environment(AppState.self) private var appState
    
    private let countries = [
        "Australia", "United States", "United Kingdom", "Canada",
        "Singapore", "Germany", "Japan", "India", "Other"
    ]
    
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
            Menu {
                ForEach(countries, id: \.self) { country in
                    Button(country) { profile.country = country }
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
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(Theme.surface)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
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

#Preview {
    KYCDocumentSelectionView(profile: .constant(KYCProfile()), onContinue: {})
        .environment(AppState(authService: MockAuthService()))
        .preferredColorScheme(.dark)
}
