//
//  CoinDetailView.swift
//  CryptoWallet
//
//  The drilldown screen for a single coin. Hero (name + price + 24h
//  change), segmented range picker (1D/7D/30D/1Y), Apple Charts-rendered
//  price line, 2x2 stats grid, About section, Add-to-Wallet CTA.
//
//  This is the screen where Apple's Charts framework justifies its
//  weight — accessibility, axis labels, and gesture support all come
//  for free. Drawing this with raw Path would be a full afternoon's
//  work and end up worse.
//

import SwiftUI
import Charts

struct CoinDetailView: View {
    
    let coinID: String
    let name: String
    let symbol: String
    let imageURL: URL?
    
    @Environment(AppState.self) private var appState
    @Environment(\.cryptoService) private var cryptoService
    
    @State private var vm = CoinDetailViewModel()
    @State private var showAddSheet = false
    
    private var reloadKey: String {
        "\(coinID)-\(appState.currency.rawValue)"
    }
    
    private var initialLoadFailed: Bool {
        vm.detail == nil && vm.error != nil
    }
    
    var body: some View {
        ZStack {
            Theme.backgroundPrimary.ignoresSafeArea()
            
            if initialLoadFailed, let error = vm.error {
                ErrorView(error: error) {
                    retryInitialLoad()
                }
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        hero
                        rangePicker
                        chart
                        statsGrid
                        Button {
                            showAddSheet = true
                        } label: {
                            Label("Add to Wallet", systemImage: "plus")
                        }
                        .buttonStyle(FoxcryptoButtonStyle())
                        
                        aboutSection
                        Color.clear.frame(height: 40)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                }
            }
        }
        .navigationTitle(name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Theme.backgroundPrimary, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    appState.toggleFavourite(coinID)
                } label: {
                    Image(systemName: appState.isFavourite(coinID) ? "star.fill" : "star")
                        .foregroundStyle(appState.isFavourite(coinID) ? Theme.accentYellow : Theme.textSecondary)
                }
            }
        }
        .task(id: reloadKey) {
            // Detail data and chart should both follow the active fiat currency.
            await vm.load(coinID: coinID, currency: appState.currency, service: cryptoService)
        }
        .sheet(isPresented: $showAddSheet) {
            NavigationStack {
                AddHoldingView(preselectedCoinID: coinID, preselectedSymbol: symbol)
            }
            .preferredColorScheme(appState.resolvedColorScheme)
        }
    }
    
    private func retryInitialLoad() {
        Task {
            await vm.load(coinID: coinID, currency: appState.currency, service: cryptoService)
        }
    }
    
    private func retryChart() {
        Task {
            await vm.changeRange(
                to: vm.range,
                coinID: coinID,
                currency: appState.currency,
                service: cryptoService
            )
        }
    }
    
    // MARK: - Hero
    
    private var hero: some View {
        HStack(alignment: .top, spacing: 14) {
            CoinIcon(url: imageURL, symbol: symbol, size: 56)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(symbol.uppercased())
                    .font(AppFont.captionBold(11))
                    .foregroundStyle(Theme.textSecondary)
                
                if let detail = vm.detail {
                    Text(PriceFormatter.currency(detail.currentPrice, currency: appState.currency))
                        .font(AppFont.display(28))
                        .foregroundStyle(Theme.textPrimary)
                    
                    Text("\(PriceFormatter.percent(detail.priceChangePercent24h ?? 0)) (24h)")
                        .font(AppFont.captionBold(13))
                        .foregroundStyle(Theme.plColour(detail.priceChangePercent24h ?? 0))
                } else {
                    Text("Loading…")
                        .font(AppFont.body(14))
                        .foregroundStyle(Theme.textSecondary)
                }
            }
            Spacer()
        }
    }
    
    // MARK: - Range picker
    
    private var rangePicker: some View {
        HStack(spacing: 4) {
            ForEach(ChartRange.allCases) { range in
                Button {
                    Task {
                        await vm.changeRange(
                            to: range,
                            coinID: coinID,
                            currency: appState.currency,
                            service: cryptoService
                        )
                    }
                } label: {
                    Text(range.label)
                        .font(AppFont.bodyMedium(13))
                        .foregroundStyle(vm.range == range ? Theme.textPrimary : Theme.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(vm.range == range ? Theme.surface : Color.clear)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
        }
        .padding(4)
        .background(Theme.surface.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
    
    // MARK: - Chart
    
    @ViewBuilder
    private var chart: some View {
        if vm.chartLoading {
            ProgressView()
                .tint(Theme.accentYellow)
                .frame(height: 200)
                .frame(maxWidth: .infinity)
        } else if vm.chart.isEmpty {
            if let error = vm.error {
                chartErrorState(error)
            } else {
                emptyChartState
            }
        } else {
            VStack(alignment: .leading, spacing: 12) {
                Chart(vm.chart) { point in
                    LineMark(
                        x: .value("Time", point.date),
                        y: .value("Price", point.price)
                    )
                    .foregroundStyle(Theme.upTint)
                    .interpolationMethod(.monotone)
                    
                    AreaMark(
                        x: .value("Time", point.date),
                        y: .value("Price", point.price)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Theme.upTint.opacity(0.3), Theme.upTint.opacity(0.0)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .interpolationMethod(.monotone)
                }
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: 4)) { _ in
                        AxisGridLine().foregroundStyle(Theme.textSecondary.opacity(0.15))
                        AxisValueLabel().foregroundStyle(Theme.textSecondary)
                    }
                }
                .chartYAxis {
                    AxisMarks(values: .automatic(desiredCount: 4)) { _ in
                        AxisGridLine().foregroundStyle(Theme.textSecondary.opacity(0.15))
                        AxisValueLabel().foregroundStyle(Theme.textSecondary)
                    }
                }
                .frame(height: 200)
                
                if let error = vm.error {
                    // Keep stale chart data visible while surfacing a failed refresh.
                    HStack(spacing: 10) {
                        Image(systemName: "exclamationmark.triangle")
                            .foregroundStyle(Theme.textSecondary)
                        Text(error.errorDescription ?? "Unable to refresh chart data.")
                            .font(AppFont.body(12))
                            .foregroundStyle(Theme.textSecondary)
                        Spacer()
                        Button("Retry", action: retryChart)
                            .font(AppFont.bodyMedium(12))
                            .foregroundStyle(Theme.accentYellow)
                    }
                }
            }
            .padding(12)
            .background(Theme.surface)
            .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius))
        }
    }
    
    private func chartErrorState(_ error: CryptoError) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 24))
                .foregroundStyle(Theme.textSecondary)
            Text(error.errorDescription ?? "Unable to load chart data.")
                .font(AppFont.body(13))
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
            Button("Retry", action: retryChart)
                .buttonStyle(FoxcryptoButtonStyle(fillsWidth: false))
        }
        .frame(height: 200)
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 20)
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius))
    }
    
    private var emptyChartState: some View {
        VStack(spacing: 10) {
            Text("No chart data available")
                .font(AppFont.body(13))
                .foregroundStyle(Theme.textSecondary)
            Button("Retry", action: retryChart)
                .buttonStyle(FoxcryptoButtonStyle(fillsWidth: false))
        }
        .frame(height: 200)
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 20)
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius))
    }
    
    // MARK: - Stats grid
    
    private var statsGrid: some View {
        LazyVGrid(
            columns: [GridItem(.flexible(), spacing: 8), GridItem(.flexible())],
            spacing: 8
        ) {
            if let detail = vm.detail {
                StatTile(label: "Market Cap",
                         value: detail.marketCap.map { PriceFormatter.compact($0, in: appState.currency) } ?? "—")
                StatTile(label: "Symbol", value: detail.symbol.uppercased())
                StatTile(label: "All-Time High",
                         value: detail.allTimeHigh.map { PriceFormatter.currency($0, currency: appState.currency) } ?? "—")
                StatTile(label: "All-Time Low",
                         value: detail.allTimeLow.map { PriceFormatter.currency($0, currency: appState.currency) } ?? "—")
            }
        }
    }
    
    // MARK: - About
    
    @ViewBuilder
    private var aboutSection: some View {
        if let detail = vm.detail, !detail.descriptionPlain.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text("About")
                    .font(AppFont.heading(16))
                    .foregroundStyle(Theme.textPrimary)
                Text(detail.descriptionPlain)
                    .font(AppFont.body(13))
                    .foregroundStyle(Theme.textSecondary)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.surface)
            .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius))
        }
    }
}

// MARK: - Stat tile

private struct StatTile: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(AppFont.caption(11))
                .foregroundStyle(Theme.textSecondary)
            Text(value)
                .font(AppFont.mono(14, weight: .semibold))
                .foregroundStyle(Theme.textPrimary)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius))
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        CoinDetailView(
            coinID: "bitcoin",
            name: "Bitcoin",
            symbol: "btc",
            imageURL: nil
        )
    }
    .environment(PreviewState.populated)
    .environment(\.cryptoService, MockCryptoService())
    .preferredColorScheme(.dark)
}
#endif
