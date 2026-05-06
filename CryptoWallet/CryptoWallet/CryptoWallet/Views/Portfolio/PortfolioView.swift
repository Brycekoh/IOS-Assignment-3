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
    @Bindable var marketVM: MarketViewModel
    @State private var showAddSheet = false
    
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
    
    private var totalValue: Double { valuedHoldings.reduce(0) { $0 + $1.currentValueUSD } }
    private var totalCost: Double { valuedHoldings.reduce(0) { $0 + $1.totalCostUSD } }
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
            SummaryTile(label: "Value", value: PriceFormatter.currency(totalValue, currency: .usd))
            SummaryTile(label: "Cost", value: PriceFormatter.currency(totalCost, currency: .usd))
            SummaryTile(
                label: "P/L",
                value: PriceFormatter.currency(totalPL, currency: .usd),
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
                        HoldingRow(valued: vh, coin: marketVM.coins.first(where: { $0.id == vh.holding.coinID }))
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
                Text(PriceFormatter.currency(valued.currentValueUSD, currency: .usd))
                    .font(AppFont.mono(14, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
                Text(PriceFormatter.percent(valued.profitLossPercent))
                    .font(AppFont.captionBold(11))
                    .foregroundStyle(Theme.plColour(valued.profitLossUSD))
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
