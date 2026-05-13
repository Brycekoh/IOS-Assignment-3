//
//  FoxcryptoComponents.swift
//  CryptoWallet
//
//  The styled primitives that appear throughout the Foxcrypto design:
//  the yellow CTA button, the dark text field, the secondary outlined
//  button, the page progress dots. Centralising them here means the
//  visual language stays consistent across every screen and any future
//  tweak (e.g. tighter corner radii) ripples everywhere automatically.
//

import SwiftUI

// MARK: - Primary yellow button
//
// The signature Foxcrypto CTA — yellow fill, dark text, full-width by
// default, big enough to feel like a primary action. Disables itself
// (greyed) when the parent says it's not ready.

struct FoxcryptoButtonStyle: ButtonStyle {
    var fillsWidth: Bool = true
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AppFont.bodyMedium(16))
            .foregroundStyle(Theme.backgroundPrimary)
            .frame(maxWidth: fillsWidth ? .infinity : nil)
            .padding(.vertical, 16)
            .padding(.horizontal, 24)
            .background(Theme.accentYellow)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .opacity(configuration.isPressed ? 0.85 : 1)
            .scaleEffect(configuration.isPressed ? 0.99 : 1)
    }
}

// MARK: - Secondary outlined button
//
// Used on the "Fast And Flexible Trading" screen for "Sign up", and
// anywhere we have a paired primary/secondary action.

struct FoxcryptoOutlineButtonStyle: ButtonStyle {
    var fillsWidth: Bool = true
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AppFont.bodyMedium(16))
            .foregroundStyle(Theme.accentYellow)
            .frame(maxWidth: fillsWidth ? .infinity : nil)
            .padding(.vertical, 14)
            .padding(.horizontal, 24)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(Theme.accentYellow, lineWidth: 1.5)
            )
            .opacity(configuration.isPressed ? 0.85 : 1)
    }
}

// MARK: - Dark text field
//
// Matches the Figma's input styling: dark surface, subtle border,
// muted placeholder, bright content. We wrap SwiftUI's TextField
// rather than building a custom one so password masking, autofill,
// and accessibility all work out of the box.

struct FoxcryptoTextField: View {
    let placeholder: String
    @Binding var text: String
    var isSecure: Bool = false
    var keyboardType: UIKeyboardType = .default
    var contentType: UITextContentType?
    
    @State private var isPasswordVisible = false
    
    var body: some View {
        HStack(spacing: 8) {
            Group {
                if isSecure && !isPasswordVisible {
                    SecureField("", text: $text, prompt: placeholderText)
                        .textContentType(contentType)
                } else {
                    TextField("", text: $text, prompt: placeholderText)
                        .keyboardType(keyboardType)
                        .textInputAutocapitalization(contentType == .emailAddress ? .never : .sentences)
                        .autocorrectionDisabled(contentType == .emailAddress || isSecure)
                        .textContentType(contentType)
                }
            }
            .foregroundStyle(Theme.textPrimary)
            .font(AppFont.body(15))
            .tint(Theme.accentYellow)
            
            if isSecure {
                Button {
                    isPasswordVisible.toggle()
                } label: {
                    Image(systemName: isPasswordVisible ? "eye" : "eye.slash")
                        .foregroundStyle(Theme.textSecondary)
                }
                .accessibilityLabel(isPasswordVisible ? "Hide password" : "Show password")
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Theme.surface.opacity(0.5), lineWidth: 0.5)
        )
    }
    
    private var placeholderText: Text {
        Text(placeholder).foregroundColor(Theme.textSecondary)
    }
}

// MARK: - Field label
//
// The thin off-white label used above every input field in the auth
// flows. Pulling it out into its own component keeps the auth views
// readable and consistent.

struct FieldLabel: View {
    let text: String
    var body: some View {
        Text(text)
            .font(AppFont.bodyMedium(14))
            .foregroundStyle(Theme.textPrimary)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Onboarding page indicator
//
// The little dash-and-dots row at the bottom of each onboarding slide.
// One dash gets the yellow accent (the active page), the rest are dim.

struct PageIndicator: View {
    let pageCount: Int
    let currentPage: Int
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<pageCount, id: \.self) { index in
                if index == currentPage {
                    Capsule()
                        .fill(Theme.accentYellow)
                        .frame(width: 24, height: 4)
                        .transition(.scale)
                } else {
                    Circle()
                        .fill(Theme.textSecondary.opacity(0.4))
                        .frame(width: 4, height: 4)
                }
            }
        }
        .animation(.easeInOut(duration: 0.25), value: currentPage)
    }
}

// MARK: - Yellow circular forward button
//
// The yellow circle with the chevron at the bottom-right of every
// onboarding slide.

struct CircularNextButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: "chevron.right")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(Theme.backgroundPrimary)
                .frame(width: 48, height: 48)
                .background(Theme.accentYellow)
                .clipShape(Circle())
        }
        .accessibilityLabel("Next")
    }
}

// MARK: - Plain dark navigation back button
//
// The tappable back-chevron that appears in nav bars throughout the
// auth and KYC flows. Wrapping it in a single view means all back
// buttons stay visually identical.

struct BackChevronButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: "arrow.left")
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(Theme.textPrimary)
                .frame(width: 32, height: 32)
                .contentShape(Rectangle())
        }
        .accessibilityLabel("Back")
    }
}
