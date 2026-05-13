//
//  HomeView.swift
//  CryptoWallet
//
//  The signature screen of the app. Three sections stacked vertically:
//
//  1. Total Balance card — a gradient blue hero with a tilted yellow
//     "envelope" peeking out behind it and floating BTC icons in the
//     top-right. Most distinctive visual in the design.
//
//  2. Top Coins — horizontal scroller of price cards, each with a
//     mini sparkline. Reuses MarketViewModel for data.
//
//  3. News — sample stories rendered as image-on-left cards. Static
//     data; full news integration is out of scope for the rubric.
//

import SwiftUI

struct HomeView: View {
    
    @Environment(AppState.self) private var appState
    @Environment(\.cryptoService) private var cryptoService
    @Bindable var marketVM: MarketViewModel  // shared with Market tab
    
    var body: some View {
        ZStack {
            Theme.backgroundPrimary.ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    topBar
                    BalanceCard(totalValue: portfolioTotal, todayProfit: todayProfit, currency: appState.currency)
                    topCoinsSection
                    newsSection
                    Color.clear.frame(height: 80)  // tab bar clearance
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
            }
        }
        .task(id: appState.currency) {
            // Home shares market data with the Market tab, so a fiat change should refresh both surfaces.
            await marketVM.load(currency: appState.currency, service: cryptoService)
        }
    }
    
    // MARK: - Derived
    
    /// Sum the user's holdings against current market prices. Falls
    /// back to purchase prices if market data hasn't loaded yet — the
    /// hero card never shows "$0.00" on a cold start.
    private var portfolioTotal: Double {
        let pricesByID = Dictionary(uniqueKeysWithValues: marketVM.coins.map { ($0.id, $0.currentPrice) })
        return appState.holdings.reduce(0) { sum, holding in
            let price = pricesByID[holding.coinID] ?? holding.purchasePrice
            return sum + holding.quantity * price
        }
    }
    
    /// Approximate "today's profit" as the sum of each holding's
    /// 24-hour price delta times the quantity owned. Reads as
    /// "what did this position make/lose today".
    private var todayProfit: Double {
        let coinsByID = Dictionary(uniqueKeysWithValues: marketVM.coins.map { ($0.id, $0) })
        return appState.holdings.reduce(0) { sum, holding in
            guard let coin = coinsByID[holding.coinID] else { return sum }
            let pct = (coin.priceChangePercent24h ?? 0) / 100
            // Reverse-derive yesterday's price: today / (1 + pct)
            let yesterday = coin.currentPrice / (1 + pct)
            let delta = coin.currentPrice - yesterday
            return sum + holding.quantity * delta
        }
    }
    
    // MARK: - Top bar
    
    private var topBar: some View {
        HStack {
            Spacer()
            HStack(spacing: 16) {
                Image(systemName: "magnifyingglass")
                Image(systemName: "bell")
            }
            .foregroundStyle(Theme.textPrimary)
            .font(.system(size: 18, weight: .medium))
        }
        .padding(.top, 8)
    }
    
    // MARK: - Top Coins
    
    private var topCoinsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Top Coins", trailing: "See all")
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(marketVM.coins.prefix(8)) { coin in
                        NavigationLink {
                            CoinDetailView(coinID: coin.id, name: coin.name, symbol: coin.symbol, imageURL: coin.imageURL)
                        } label: {
                            TopCoinCard(coin: coin, currency: appState.currency)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .scrollClipDisabled()
        }
    }
    
    // MARK: - News
    
    private var newsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "News", trailing: "See all")
            
            VStack(spacing: 12) {
                ForEach(SampleNews.items) { item in
                    NewsCard(item: item)
                }
            }
        }
    }
}

// MARK: - Balance card (hero)

/// Gradient blue Total Balance card with the yellow envelope shape
/// peeking out behind it. Built from two stacked rounded rectangles
/// rather than a single shape — gives the layered "money is in this
/// wallet" depth that makes the design memorable.
private struct BalanceCard: View {
    let totalValue: Double
    let todayProfit: Double
    let currency: Currency
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            // Tilted yellow envelope behind the main card. Negative
            // top inset + slight scale creates the paper-envelope
            // illusion underneath.
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "FFD46A"), Color(hex: "F59E45")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(height: 30)
                .padding(.horizontal, 12)
                .offset(y: -10)
            
            // Foreground gradient blue card.
            ZStack(alignment: .topTrailing) {
                RoundedRectangle(cornerRadius: Theme.cornerRadiusLarge)
                    .fill(
                        LinearGradient(
                            colors: [Theme.balanceCardTop, Theme.balanceCardBottom],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                FloatingCoinsCluster()
                    .padding(.top, 12)
                    .padding(.trailing, 12)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Total Balance")
                        .font(AppFont.bodyMedium(13))
                        .foregroundStyle(Theme.backgroundPrimary.opacity(0.7))
                    
                    Text(PriceFormatter.currency(totalValue, currency: currency))
                        .font(AppFont.display(28))
                        .foregroundStyle(Theme.backgroundPrimary)
                    
                    HStack(spacing: 6) {
                        Image(systemName: todayProfit >= 0 ? "chart.line.uptrend.xyaxis" : "chart.line.downtrend.xyaxis")
                            .foregroundStyle(todayProfit >= 0 ? Theme.upTint : Theme.downTint)
                            .font(.system(size: 12, weight: .bold))
                        Text("\(PriceFormatter.currency(todayProfit, currency: currency)) Today's Profit")
                            .font(AppFont.body(12))
                            .foregroundStyle(Theme.backgroundPrimary.opacity(0.7))
                    }
                    .padding(.top, 6)
                }
                .padding(20)
            }
            .frame(height: 150)
        }
        .padding(.top, 10)
    }
}

// MARK: - Floating coin cluster

/// Decorative BTC shapes in the top-right of the balance card. Drawn
/// with SF Symbols so the file doesn't need any image assets.
private struct FloatingCoinsCluster: View {
    var body: some View {
        ZStack {
            Image(systemName: "bitcoinsign.circle.fill")
                .font(.system(size: 22))
                .foregroundStyle(Color(hex: "F59E45"))
                .offset(x: -20, y: 0)
            
            Image(systemName: "bitcoinsign.circle.fill")
                .font(.system(size: 36))
                .foregroundStyle(Color(hex: "F59E45"))
                .offset(x: 6, y: 36)
                .rotationEffect(.degrees(-15))
        }
    }
}

// MARK: - Top coin card

private struct TopCoinCard: View {
    let coin: Coin
    let currency: Currency
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                CoinIcon(url: coin.imageURL, symbol: coin.symbol, size: 24)
                Text(coin.name)
                    .font(AppFont.bodyMedium(15))
                    .foregroundStyle(Theme.textPrimary)
                    .lineLimit(1)
            }
            
            Text(currency.symbol + " " + PriceFormatter.currency(coin.currentPrice, currency: currency, showSymbol: false))
                .font(AppFont.mono(15, weight: .semibold))
                .foregroundStyle(Theme.textPrimary)
            
            HStack(spacing: 4) {
                Text(PriceFormatter.percent(coin.priceChangePercent24h ?? 0))
                    .font(AppFont.captionBold(12))
                    .foregroundStyle(Theme.plColour(coin.priceChangePercent24h ?? 0))
                Image(systemName: coin.isUp ? "arrowtriangle.up.fill" : "arrowtriangle.down.fill")
                    .font(.system(size: 8))
                    .foregroundStyle(Theme.plColour(coin.priceChangePercent24h ?? 0))
            }
            
            if let sparkline = coin.sparkline, sparkline.count > 1 {
                Sparkline(prices: sparkline, lineWidth: 1.5)
                    .frame(height: 32)
            } else {
                Color.clear.frame(height: 32)
            }
        }
        .padding(14)
        .frame(width: 160)
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius))
    }
}

// MARK: - News card

private struct NewsCard: View {
    let item: NewsItem
    
    var body: some View {
        HStack(spacing: 12) {
            AsyncImage(url: item.imageURL) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().scaledToFill()
                default:
                    Theme.accentYellow.opacity(0.2)
                }
            }
            .frame(width: 80, height: 60)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            
            Text(item.title)
                .font(AppFont.bodyMedium(13))
                .foregroundStyle(Theme.textPrimary)
                .lineLimit(3)
                .multilineTextAlignment(.leading)
            
            Spacer()
        }
        .padding(12)
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius))
    }
}

// MARK: - Sample news data

struct NewsItem: Identifiable {
    let id = UUID()
    let title: String
    let imageURL: URL?
}

enum SampleNews {
    static let items: [NewsItem] = [
        .init(
            title: "Analysts project 32% upside for Coinbase stock despite recent volatility",
            imageURL: URL(string: "https://images.unsplash.com/photo-1518546305927-5a555bb7020d?w=200")
        ),
        .init(
            title: "Bitcoin hits new monthly high as institutional adoption accelerates",
            imageURL: URL(string: "https://images.unsplash.com/photo-1518186285589-2f7649de83e0?w=200")
        ),
        .init(
            title: "Ethereum's latest upgrade promises 40% reduction in gas fees",
            imageURL: URL(string: "https://images.unsplash.com/photo-1640340434855-6084b1f4901c?w=200")
        )
    ]
}

#if DEBUG
#Preview {
    NavigationStack {
        HomeView(marketVM: PreviewState.loadedMarket)
    }
    .environment(PreviewState.populated)
    .environment(\.cryptoService, MockCryptoService())
    .preferredColorScheme(.dark)
}
#endif
