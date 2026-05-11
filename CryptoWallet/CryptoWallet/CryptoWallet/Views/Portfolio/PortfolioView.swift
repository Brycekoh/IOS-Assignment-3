//
//  PortfolioView.swift
//  CryptoWallet
//
//  The "Porfolio" tab (sic — matches the Figma's spelling). Three-cell
//  summary across the top (Value / Cost / P&L), holdings list with
//  swipe-to-remove. Empty state guides new users to add their first
//  position.
//

import SwiftUI

struct PortfolioView: View {
    
    @Environment(AppState.self) private var appState
    @Environment(\.cryptoService) private var cryptoService
    @Bindable var marketVM: MarketViewModel
    @State private var showAddSheet = false
    @State private var usdReferenceCoins: [Coin] = []
    
    var body: some View {
        ZStack {
            Theme.backgroundPrimary.ignoresSafeArea()
            
            VStack(spacing: 16) {
                header
                summaryStrip
                holdingsList
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
        }
        .sheet(isPresented: $showAddSheet) {
            NavigationStack { AddHoldingView() }
                .preferredColorScheme(.dark)
        }
        .task(id: appState.currency) {
            await loadUSDReferenceCoins()
        }
    }
    
    // MARK: - Derived totals
    
    /// Joins holdings with current market prices to produce live values.
    /// Computed from current `marketVM.coins` so it updates when the
    /// market refreshes — no need for explicit pub/sub between tabs.
    private var valuedHoldings: [ValuedHolding] {
        let pricesByID = Dictionary(uniqueKeysWithValues: marketVM.coins.map { ($0.id, $0.currentPrice) })
        return appState.holdings.map { holding in
            ValuedHolding(
                holding: holding,
                currentPriceUSD: pricesByID[holding.coinID] ?? holding.purchasePrice
            )
        }
    }
    
    private var totalValue: Double { valuedHoldings.reduce(0) { $0 + displayValue(for: $1) } }
    private var totalCost: Double { valuedHoldings.reduce(0) { $0 + displayCost(for: $1) } }
    private var totalPL: Double { totalValue - totalCost }
    
    // MARK: - Header
    
    private var header: some View {
        HStack {
            Text("Portfolio")
                .font(AppFont.display(28))
                .foregroundStyle(Theme.textPrimary)
            Spacer()
            Button {
                showAddSheet = true
            } label: {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(Theme.accentYellow)
            }
        }
        .padding(.top, 8)
    }
    
    // MARK: - Summary strip
    
    private var summaryStrip: some View {
        HStack(spacing: 8) {
            SummaryTile(label: "Value", value: PriceFormatter.currency(totalValue, currency: appState.currency))
            SummaryTile(label: "Cost", value: PriceFormatter.currency(totalCost, currency: appState.currency))
            SummaryTile(
                label: "P/L",
                value: PriceFormatter.currency(totalPL, currency: appState.currency),
                tint: Theme.plColour(totalPL)
            )
        }
    }
    
    // MARK: - Holdings list
    
    @ViewBuilder
    private var holdingsList: some View {
        if appState.holdings.isEmpty {
            EmptyStateView(
                systemImage: "wallet.pass",
                title: "No holdings yet",
                message: "Tap + to add your first position. Your portfolio totals will populate as soon as you do."
            )
        } else {
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(valuedHoldings, id: \.holding.id) { vh in
                        HoldingRow(
                            valued: vh,
                            coin: marketVM.coins.first(where: { $0.id == vh.holding.coinID }),
                            currency: appState.currency,
                            currentValue: displayValue(for: vh),
                            profitLoss: displayProfitLoss(for: vh),
                            profitLossPercent: displayProfitLossPercent(for: vh)
                        )
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    appState.removeHolding(id: vh.holding.id)
                                } label: {
                                    Label("Remove", systemImage: "trash")
                                }
                            }
                    }
                    Color.clear.frame(height: 80)  // tab bar clearance
                }
            }
        }
    }
    
    // Holdings keep a USD cost basis internally; convert it into the active
    // display currency using the current USD-vs-selected quote for the same coin.
    private func displayCost(for valued: ValuedHolding) -> Double {
        valued.totalCostUSD * conversionRate(for: valued.holding.coinID)
    }
    
    private func displayValue(for valued: ValuedHolding) -> Double {
        valued.currentValueUSD
    }
    
    private func displayProfitLoss(for valued: ValuedHolding) -> Double {
        displayValue(for: valued) - displayCost(for: valued)
    }
    
    private func displayProfitLossPercent(for valued: ValuedHolding) -> Double {
        let displayCost = displayCost(for: valued)
        guard displayCost > 0 else { return 0 }
        return (displayProfitLoss(for: valued) / displayCost) * 100
    }
    
    private func conversionRate(for coinID: String) -> Double {
        guard appState.currency != .usd else { return 1 }
        guard let displayCoin = marketVM.coins.first(where: { $0.id == coinID }),
              let usdCoin = usdReferenceCoins.first(where: { $0.id == coinID }),
              usdCoin.currentPrice > 0 else { return 1 }
        return displayCoin.currentPrice / usdCoin.currentPrice
    }
    
    private func loadUSDReferenceCoins() async {
        guard appState.currency != .usd else {
            usdReferenceCoins = []
            return
        }
        
        do {
            usdReferenceCoins = try await cryptoService.fetchMarkets(currency: .usd, perPage: 50, page: 1)
        } catch {
            usdReferenceCoins = []
        }
    }
}

// MARK: - Summary tile

private struct SummaryTile: View {
    let label: String
    let value: String
    var tint: Color = Theme.textPrimary
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(AppFont.caption(11))
                .foregroundStyle(Theme.textSecondary)
            Text(value)
                .font(AppFont.mono(14, weight: .semibold))
                .foregroundStyle(tint)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius))
    }
}

// MARK: - Holding row

private struct HoldingRow: View {
    let valued: ValuedHolding
    let coin: Coin?
    let currency: Currency
    let currentValue: Double
    let profitLoss: Double
    let profitLossPercent: Double
    
    var body: some View {
        HStack(spacing: 12) {
            CoinIcon(url: coin?.imageURL, symbol: coin?.symbol ?? valued.holding.coinID, size: 36)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(coin?.name ?? valued.holding.coinID.capitalized)
                    .font(AppFont.bodyMedium(14))
                    .foregroundStyle(Theme.textPrimary)
                Text(PriceFormatter.quantity(valued.holding.quantity, symbol: coin?.symbol ?? "—"))
                    .font(AppFont.caption(12))
                    .foregroundStyle(Theme.textSecondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text(PriceFormatter.currency(currentValue, currency: currency))
                    .font(AppFont.mono(14, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
                Text(PriceFormatter.percent(profitLossPercent))
                    .font(AppFont.captionBold(11))
                    .foregroundStyle(Theme.plColour(profitLoss))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        PortfolioView(marketVM: PreviewState.loadedMarket)
    }
    .environment(PreviewState.populated)
    .environment(\.cryptoService, MockCryptoService())
    .preferredColorScheme(.dark)
}

#Preview("Empty") {
    NavigationStack {
        PortfolioView(marketVM: PreviewState.loadedMarket)
    }
    .environment(PreviewState.empty)
    .environment(\.cryptoService, MockCryptoService())
    .preferredColorScheme(.dark)
}
#endif
