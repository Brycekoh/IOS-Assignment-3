//
//  KYCComponents.swift
//  CryptoWallet
//
//  Tappable upload slot + rule-row line items shared between the
//  KYC document upload and selfie steps. Pulled into their own
//  file so it's obvious they belong to multiple screens — not a
//  helper buried in a single screen file.
//

import SwiftUI

// MARK: - Upload slot

/// Tappable square that toggles between empty (camera icon + label)
/// and filled (yellow check). Real photo capture would replace this
/// with PhotosPicker or a UIImagePickerController bridge — left as a
/// "future work" item flagged in the README.
struct UploadSlot: View {
    let title: String
    let isFilled: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: isFilled ? "checkmark.circle.fill" : "camera")
                    .font(.system(size: 28, weight: .light))
                    .foregroundStyle(isFilled ? Theme.accentYellow : Theme.textSecondary)
                Text(isFilled ? "Photo added" : title)
                    .font(AppFont.body(13))
                    .foregroundStyle(isFilled ? Theme.accentYellow : Theme.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 110)
            .background(Theme.surface)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        isFilled ? Theme.accentYellow.opacity(0.5) : Color.clear,
                        lineWidth: 1
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Rule row

/// Single line of the checklist with a green check or red X. Positive
/// rules use green, negatives red — exactly the colour scheme used in
/// the Figma's KYC screens.
struct RuleRow: View {
    let text: String
    let positive: Bool
    
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: positive ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundStyle(positive ? Theme.upTint : Theme.downTint)
                .font(.system(size: 16, weight: .medium))
            Text(text)
                .font(AppFont.body(13))
                .foregroundStyle(Theme.textPrimary)
        }
    }
}

// MARK: - Privacy notice

/// Reused across all three KYC steps. Single source of truth for the
/// "we keep your data safe" disclaimer copy and styling.
struct KYCPrivacyNotice: View {
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "checkmark.square.fill")
                .foregroundStyle(Theme.textSecondary)
                .font(.system(size: 16, weight: .medium))
            Text("This information is used for identity verification only, and will be kept secure by CrypCoin")
                .font(AppFont.caption(11))
                .foregroundStyle(Theme.textSecondary)
        }
    }
}
