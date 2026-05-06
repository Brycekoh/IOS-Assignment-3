//
//  MarketView.swift
//  CryptoWallet
//
//  The Market tab. Top-bar search, two-pill filter (All / Favourites),
//  list of coins with price + 24h change + sparkline, tap-through to
//  detail. Uses MarketViewModel for data and SearchViewModel for the
//  debounced search query.
//
//  Designed so the Home screen can share the same MarketViewModel
//  instance — that way switching between tabs doesn't reload data and
//  Top Coins on Home stays in sync with the Market list.
//

import SwiftUI

struct MarketView: View {
    
    @Environment(AppState.self) private var appState
    @Environment(\.cryptoService) private var cryptoService
    @Bindable var marketVM: MarketViewModel
    
    @State private var searchVM = SearchViewModel()
    @State private var query = ""
    @State private var filter: Filter = .all
    
    enum Filter: String, CaseIterable, Identifiable {
        case all = "All"
        case favourites = "Favourites"
        var id: String { rawValue }
    }
    
    var body: some View {
        ZStack {
            Theme.backgroundPrimary.ignoresSafeArea()
            
            VStack(spacing: 16) {
                header
                searchBar
                filterPills
                content
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
        }
        .task {
            if marketVM.coins.isEmpty {
                await marketVM.load(currency: appState.currency, service: cryptoService)
            }
        }
        .onChange(of: query) { _, newValue in
            // Search runs only when user types > 1 char to avoid
            // a flood of single-letter requests.
            if newValue.count > 1 {
                searchVM.search(query: newValue, service: cryptoService)
            } else {
                searchVM.clear()
            }
        }
    }
    
    // MARK: - Header
    
    private var header: some View {
        HStack {
            Text("Market")
                .font(AppFont.display(28))
                .foregroundStyle(Theme.textPrimary)
            Spacer()
        }
        .padding(.top, 8)
    }
    
    // MARK: - Search bar
    
    private var searchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(Theme.textSecondary)
            TextField("", text: $query, prompt: Text("Search coins…").foregroundColor(Theme.textSecondary))
                .foregroundStyle(Theme.textPrimary)
                .font(AppFont.body(15))
                .tint(Theme.accentYellow)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
            if !query.isEmpty {
                Button {
                    query = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(Theme.textSecondary)
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
    
    // MARK: - Filter pills
    
    private var filterPills: some View {
        HStack(spacing: 8) {
            ForEach(Filter.allCases) { f in
                Button {
                    filter = f
                } label: {
                    Text(f.rawValue)
                        .font(AppFont.bodyMedium(13))
                        .foregroundStyle(filter == f ? Theme.backgroundPrimary : Theme.textSecondary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(filter == f ? Theme.accentYellow : Theme.surface)
                        .clipShape(Capsule())
                }
            }
            Spacer()
        }
    }
    
    // MARK: - Content
    
    @ViewBuilder
    private var content: some View {
        if !query.isEmpty, query.count > 1 {
            // Search results take precedence over the regular list
            // when the user is actively searching.
            switch searchVM.phase {
            case .idle, .loading:
                ProgressView().tint(Theme.accentYellow)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            case .loaded(let results):
                if results.isEmpty {
                    EmptyStateView(systemImage: "magnifyingglass",
                                   title: "No matches",
                                   message: "Try a different name or symbol.")
                } else {
                    searchList(results: results)
                }
            case .failed(let error):
                ErrorView(error: error) {
                    searchVM.search(query: query, service: cryptoService)
                }
            }
        } else {
            mainList
        }
    }
    
    private var filteredCoins: [Coin] {
        switch filter {
        case .all:        return marketVM.coins
        case .favourites: return marketVM.coins.filter { appState.isFavourite($0.id) }
        }
    }
    
    @ViewBuilder
    private var mainList: some View {
        switch marketVM.phase {
        case .idle, .loading:
            ProgressView().tint(Theme.accentYellow)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        case .loaded:
            if filteredCoins.isEmpty {
                EmptyStateView(
                    systemImage: filter == .favourites ? "star" : "tray",
                    title: filter == .favourites ? "No favourites yet" : "No coins",
                    message: filter == .favourites ? "Tap the star on a coin's detail page to add it here." : "Pull down to refresh."
                )
            } else {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(filteredCoins) { coin in
                            NavigationLink {
                                CoinDetailView(coinID: coin.id, name: coin.name, symbol: coin.symbol, imageURL: coin.imageURL)
                            } label: {
                                MarketRow(coin: coin)
                            }
                            .buttonStyle(.plain)
                        }
                        Color.clear.frame(height: 80)  // tab bar clearance
                    }
                }
                .refreshable {
                    await marketVM.load(currency: appState.currency, service: cryptoService)
                }
            }
        case .failed(let error):
            ErrorView(error: error) {
                Task { await marketVM.load(currency: appState.currency, service: cryptoService) }
            }
        }
    }
    
    private func searchList(results: [Coin]) -> some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                ForEach(results) { coin in
                    NavigationLink {
                        CoinDetailView(coinID: coin.id, name: coin.name, symbol: coin.symbol, imageURL: coin.imageURL)
                    } label: {
                        MarketRow(coin: coin)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

// MARK: - Market row

/// One row of the Market list. Icon on the left, name + symbol,
/// sparkline filling the middle, price + change on the right.
private struct MarketRow: View {
    let coin: Coin
    
    var body: some View {
        HStack(spacing: 12) {
            CoinIcon(url: coin.imageURL, symbol: coin.symbol, size: 36)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(coin.name)
                    .font(AppFont.bodyMedium(14))
                    .foregroundStyle(Theme.textPrimary)
                    .lineLimit(1)
                Text(coin.symbol.uppercased())
                    .font(AppFont.caption(12))
                    .foregroundStyle(Theme.textSecondary)
            }
            .frame(width: 80, alignment: .leading)
            
            if let sparkline = coin.sparkline, sparkline.count > 1 {
                Sparkline(prices: sparkline, lineWidth: 1.2, fillUnder: false)
                    .frame(maxWidth: .infinity)
                    .frame(height: 24)
            } else {
                Color.clear.frame(maxWidth: .infinity)
            }
            
            VStack(alignment: .trailing, spacing: 2) {
                Text(PriceFormatter.currency(coin.currentPrice, currency: .usd))
                    .font(AppFont.mono(14, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
                Text(PriceFormatter.percent(coin.priceChangePercent24h ?? 0))
                    .font(AppFont.captionBold(11))
                    .foregroundStyle(Theme.plColour(coin.priceChangePercent24h ?? 0))
            }
            .frame(minWidth: 80, alignment: .trailing)
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
        MarketView(marketVM: PreviewState.loadedMarket)
    }
    .environment(PreviewState.populated)
    .environment(\.cryptoService, MockCryptoService())
    .preferredColorScheme(.dark)
}
#endif
