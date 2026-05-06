//
//  SharedViews.swift
//  CryptoWallet
//
//  Small, reusable view components used across the app. Pulling these
//  out keeps each screen file focused on its own logic and gives us
//  a consistent visual language across screens.
//

import SwiftUI

// MARK: - Coin icon

/// AsyncImage wrapper that falls back to a coloured circle with the
/// coin's first letter when the URL is missing or fails. Means the UI
/// never has a blank gap, even with mock data that has nil URLs.
struct CoinIcon: View {
    let url: URL?
    let symbol: String
    var size: CGFloat = 36
    
    var body: some View {
        Group {
            if let url {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().scaledToFit()
                    default:
                        placeholder
                    }
                }
            } else {
                placeholder
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
    }
    
    private var placeholder: some View {
        ZStack {
            Circle().fill(Theme.accentYellow.opacity(0.18))
            Text(String(symbol.prefix(1)).uppercased())
                .font(.system(size: size * 0.45, weight: .bold, design: .rounded))
                .foregroundStyle(Theme.accentYellow)
        }
    }
}

// MARK: - Sparkline

/// Minimal line chart of recent prices, coloured by whether the period
/// ended higher or lower than it started. Drawn with a Path rather than
/// the Charts framework because it's tiny and decorative — using Charts
/// here would be overkill. Filled gradient under the line gives it the
/// "tucked card" look from the Figma's Top Coin cards.
struct Sparkline: View {
    let prices: [Double]
    var lineWidth: CGFloat = 1.8
    var fillUnder: Bool = true
    
    var body: some View {
        GeometryReader { geo in
            if prices.count > 1,
               let minPrice = prices.min(),
               let maxPrice = prices.max(),
               maxPrice > minPrice {
                let range = maxPrice - minPrice
                let stepX = geo.size.width / CGFloat(prices.count - 1)
                let isUp = (prices.last ?? 0) >= (prices.first ?? 0)
                let strokeColour = isUp ? Theme.upTint : Theme.downTint
                
                ZStack {
                    if fillUnder {
                        Path { path in
                            for (index, value) in prices.enumerated() {
                                let x = CGFloat(index) * stepX
                                let y = geo.size.height * (1 - CGFloat((value - minPrice) / range))
                                if index == 0 {
                                    path.move(to: CGPoint(x: x, y: y))
                                } else {
                                    path.addLine(to: CGPoint(x: x, y: y))
                                }
                            }
                            path.addLine(to: CGPoint(x: geo.size.width, y: geo.size.height))
                            path.addLine(to: CGPoint(x: 0, y: geo.size.height))
                            path.closeSubpath()
                        }
                        .fill(
                            LinearGradient(
                                colors: [strokeColour.opacity(0.25), strokeColour.opacity(0.0)],
                                startPoint: .top, endPoint: .bottom
                            )
                        )
                    }
                    
                    Path { path in
                        for (index, value) in prices.enumerated() {
                            let x = CGFloat(index) * stepX
                            let y = geo.size.height * (1 - CGFloat((value - minPrice) / range))
                            if index == 0 {
                                path.move(to: CGPoint(x: x, y: y))
                            } else {
                                path.addLine(to: CGPoint(x: x, y: y))
                            }
                        }
                    }
                    .stroke(
                        strokeColour,
                        style: .init(lineWidth: lineWidth, lineCap: .round, lineJoin: .round)
                    )
                }
            }
        }
    }
}

// MARK: - Error banner

/// Standard error UI used by every screen that loads data. Takes a
/// closure for retry so the parent decides what "try again" actually
/// does. Single source of truth for error styling.
struct ErrorView: View {
    let error: CryptoError
    let onRetry: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 40))
                .foregroundStyle(Theme.textSecondary)
            Text("Something went wrong")
                .font(AppFont.heading(18))
                .foregroundStyle(Theme.textPrimary)
            Text(error.errorDescription ?? "Unknown error")
                .font(AppFont.body(14))
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Button("Try Again", action: onRetry)
                .buttonStyle(FoxcryptoButtonStyle(fillsWidth: false))
                .padding(.top, 4)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

// MARK: - Empty state

/// Shown when a list is genuinely empty (no holdings, no favourites,
/// no search results). Configurable so each screen can describe its
/// own empty state — re-using styling but not copy.
struct EmptyStateView: View {
    let systemImage: String
    let title: String
    let message: String
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.system(size: 48))
                .foregroundStyle(Theme.textSecondary.opacity(0.6))
            Text(title)
                .font(AppFont.heading(18))
                .foregroundStyle(Theme.textPrimary)
            Text(message)
                .font(AppFont.body(14))
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Section header

/// "Top Coins" / "News" / "Holdings" — the small section title with an
/// optional "See all" trailing accent. Used on the Home screen and
/// elsewhere where lists need labelling.
struct SectionHeader: View {
    let title: String
    var trailing: String? = nil
    var trailingAction: (() -> Void)? = nil
    
    var body: some View {
        HStack {
            Text(title)
                .font(AppFont.heading(18))
                .foregroundStyle(Theme.textPrimary)
            Spacer()
            if let trailing {
                Button(trailing) { trailingAction?() }
                    .font(AppFont.bodyMedium(14))
                    .foregroundStyle(Theme.accentYellow)
            }
        }
    }
}
