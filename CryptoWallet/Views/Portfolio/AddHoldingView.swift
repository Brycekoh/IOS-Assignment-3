//
//  AddHoldingView.swift
//  CryptoWallet
//
//  Sheet for adding a new position to the portfolio. Three inputs:
//  coin (Menu picker, prefilled when launched from Detail), quantity
//  (decimal pad), purchase price (decimal pad). Live preview row at
//  the top shows what the user is currently building.
//
//  Save button is disabled until all inputs are valid — no chance of
//  saving zero-quantity rows.
//

import SwiftUI

struct AddHoldingView: View {
    
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss
    
    /// When this sheet is opened from a coin's Detail screen, we
    /// preselect so the user doesn't have to find the coin again.
    var preselectedCoinID: String?
    var preselectedSymbol: String?
    
    @State private var selectedCoinID: String = ""
    @State private var selectedSymbol: String = ""
    @State private var selectedName: String = ""
    @State private var quantityString = ""
    @State private var priceString = ""
    @State private var availableCoins: [Coin] = []
    
    @Environment(\.cryptoService) private var cryptoService
    
    private var quantity: Double { Double(quantityString.replacingOccurrences(of: ",", with: ".")) ?? 0 }
    private var price: Double { Double(priceString.replacingOccurrences(of: ",", with: ".")) ?? 0 }
    private var totalCost: Double { quantity * price }
    private var canSave: Bool { !selectedCoinID.isEmpty && quantity > 0 && price > 0 }
    
    var body: some View {
        ZStack {
            Theme.backgroundPrimary.ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    coinSection
                    quantitySection
                    priceSection
                    summarySection
                }
                .padding(20)
            }
        }
        .navigationTitle("Add Holding")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Theme.backgroundPrimary, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Cancel") { dismiss() }
                    .foregroundStyle(Theme.accentYellow)
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button("Save") { save() }
                    .disabled(!canSave)
                    .foregroundStyle(canSave ? Theme.accentYellow : Theme.textSecondary)
                    .fontWeight(.semibold)
            }
        }
        .task {
            await loadCoins()
            // Apply preselection once the coin list has loaded so we
            // can pull the matching name out of it for display.
            if let id = preselectedCoinID {
                selectedCoinID = id
                if let coin = availableCoins.first(where: { $0.id == id }) {
                    selectedName = coin.name
                    selectedSymbol = coin.symbol
                } else if let symbol = preselectedSymbol {
                    selectedSymbol = symbol
                    selectedName = id.capitalized
                }
            }
        }
    }
    
    // MARK: - Sections
    
    private var coinSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            FieldLabel(text: "Coin")
            Menu {
                ForEach(availableCoins) { coin in
                    Button("\(coin.name) (\(coin.symbol.uppercased()))") {
                        selectedCoinID = coin.id
                        selectedName = coin.name
                        selectedSymbol = coin.symbol
                    }
                }
            } label: {
                HStack {
                    if !selectedCoinID.isEmpty {
                        Text("\(selectedName) (\(selectedSymbol.uppercased()))")
                            .font(AppFont.body(15))
                            .foregroundStyle(Theme.textPrimary)
                    } else {
                        Text("Select a coin")
                            .font(AppFont.body(15))
                            .foregroundStyle(Theme.textSecondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Theme.textSecondary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(Theme.surface)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
    }
    
    private var quantitySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            FieldLabel(text: "Quantity")
            FoxcryptoTextField(
                placeholder: "0.0",
                text: $quantityString,
                keyboardType: .decimalPad
            )
            Text("How many \(selectedSymbol.isEmpty ? "units" : selectedSymbol.uppercased()) do you own?")
                .font(AppFont.caption(11))
                .foregroundStyle(Theme.textSecondary)
        }
    }
    
    private var priceSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            FieldLabel(text: "Purchase Price (USD)")
            FoxcryptoTextField(
                placeholder: "0.00",
                text: $priceString,
                keyboardType: .decimalPad
            )
            HStack {
                Text("What you paid per unit when you bought.")
                    .font(AppFont.caption(11))
                    .foregroundStyle(Theme.textSecondary)
                Spacer()
                if let coin = availableCoins.first(where: { $0.id == selectedCoinID }) {
                    Button {
                        priceString = String(format: "%.2f", coin.currentPrice)
                    } label: {
                        Text("Use current (\(PriceFormatter.currency(coin.currentPrice, currency: .usd)))")
                            .font(AppFont.captionBold(11))
                            .foregroundStyle(Theme.accentYellow)
                    }
                }
            }
        }
    }
    
    private var summarySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            FieldLabel(text: "Summary")
            HStack {
                Text("Total cost")
                    .font(AppFont.body(13))
                    .foregroundStyle(Theme.textSecondary)
                Spacer()
                Text(canSave ? PriceFormatter.currency(totalCost, currency: .usd) : "—")
                    .font(AppFont.mono(14, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
            }
            .padding(14)
            .background(Theme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .opacity(canSave ? 1 : 0.5)
        }
    }
    
    // MARK: - Actions
    
    private func save() {
        let holding = Holding(
            coinID: selectedCoinID,
            symbol: selectedSymbol,
            name: selectedName,
            quantity: quantity,
            purchasePrice: price
        )
        appState.addHolding(holding)
        Haptics.success()
        dismiss()
    }
    
    private func loadCoins() async {
        do {
            availableCoins = try await cryptoService.fetchMarkets(currency: .usd, perPage: 50, page: 1)
        } catch {
            // Fall back to mock data for the picker so the form still
            // works offline. Avoids a useless empty Menu.
            availableCoins = (try? await MockCryptoService().fetchMarkets(currency: .usd, perPage: 50, page: 1)) ?? []
        }
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        AddHoldingView()
    }
    .environment(PreviewState.populated)
    .environment(\.cryptoService, MockCryptoService())
    .preferredColorScheme(.dark)
}
#endif
