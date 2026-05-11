//
//  RootTabView.swift
//  CryptoWallet
//
//  Custom tab bar implementation matching the Figma's bottom dock:
//  4 tabs (Home / Market / Porfolio / Setting — sic from the design)
//  with a yellow circular + button overlapping the bar between
//  Market and Porfolio.
//
//  Why custom instead of SwiftUI's TabView:
//    1. SwiftUI's tab bar can't have a centre button that's not a tab.
//    2. The Figma's labels and styling don't match the system look.
//    3. The yellow + button needs to launch a sheet, not switch tabs.
//
//  We share a single MarketViewModel between the Home and Market tabs
//  so loading happens once, and switching tabs is instant.
//

import SwiftUI

@MainActor
struct RootTabView: View {
    
    @Environment(AppState.self) private var appState
    @Environment(\.cryptoService) private var cryptoService
    
    @State private var selectedTab: Tab = .home
    @State private var showAddSheet = false
    @State private var showSettings = false
    @State private var marketVM = MarketViewModel()
    
    enum Tab: String, CaseIterable, Identifiable {
        case home, market, portfolio
        var id: String { rawValue }
        
        // Tab labels mirror the Figma's exact spelling — "Porfolio"
        // and "Setting" (sic). Internally we still use proper names.
        var label: String {
            switch self {
            case .home:      return "Home"
            case .market:    return "Market"
            case .portfolio: return "Porfolio"
            }
        }
        
        var systemImage: String {
            switch self {
            case .home:      return "house.fill"
            case .market:    return "chart.bar.fill"
            case .portfolio: return "chart.pie.fill"
            }
        }
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            Theme.backgroundPrimary.ignoresSafeArea()
            
            // Use TabView so each tab keeps its own NavigationStack and
            // pushed state survives a tab switch. We hide TabView's
            // built-in bar and overlay our own so we can match the
            // Figma exactly.
            TabView(selection: $selectedTab) {
                NavigationStack {
                    HomeView(marketVM: marketVM)
                }.tag(Tab.home)
                
                NavigationStack {
                    MarketView(marketVM: marketVM)
                }.tag(Tab.market)
                
                NavigationStack {
                    PortfolioView(marketVM: marketVM)
                }.tag(Tab.portfolio)
            }
            .tint(Theme.accentYellow)
            .toolbar(.hidden, for: .tabBar)
            
            tabBar
        }
        .sheet(isPresented: $showAddSheet) {
            NavigationStack { AddHoldingView() }
                .preferredColorScheme(.dark)
        }
        .fullScreenCover(isPresented: $showSettings) {
            NavigationStack {
                SettingsView(
                    showsCloseButton: true,
                    onClose: { showSettings = false }
                )
            }
            .preferredColorScheme(.dark)
        }
    }
    
    // MARK: - Tab bar
    
    private var tabBar: some View {
        ZStack(alignment: .top) {
            HStack(spacing: 0) {
                tabButton(.home)
                tabButton(.market)
                Color.clear.frame(maxWidth: .infinity)  // gap for + button
                tabButton(.portfolio)
                settingsButton
            }
            .padding(.horizontal, 12)
            .padding(.top, 12)
            .padding(.bottom, 24)
            .background(
                Theme.backgroundPrimary
                    .shadow(color: .black.opacity(0.4), radius: 8, y: -2)
            )
            
            // The centre + button overlapping the bar.
            plusButton
                .offset(y: -22)
        }
    }
    
    private var settingsButton: some View {
        Button {
            Haptics.selection()
            showSettings = true
        } label: {
            VStack(spacing: 4) {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 18, weight: .medium))
                Text("Setting")
                    .font(AppFont.caption(10))
            }
            .foregroundStyle(Theme.textSecondary)
            .frame(maxWidth: .infinity)
        }
    }
    
    private func tabButton(_ tab: Tab) -> some View {
        Button {
            if selectedTab != tab {
                Haptics.selection()
                withAnimation(.easeInOut(duration: 0.2)) {
                    selectedTab = tab
                }
            }
        } label: {
            VStack(spacing: 4) {
                Image(systemName: tab.systemImage)
                    .font(.system(size: 18, weight: .medium))
                Text(tab.label)
                    .font(AppFont.caption(10))
            }
            .foregroundStyle(selectedTab == tab ? Theme.accentYellow : Theme.textSecondary)
            .frame(maxWidth: .infinity)
        }
    }
    
    private var plusButton: some View {
        Button {
            Haptics.medium()
            showAddSheet = true
        } label: {
            ZStack {
                Circle()
                    .fill(Theme.accentYellow)
                    .frame(width: 56, height: 56)
                    .shadow(color: Theme.accentYellow.opacity(0.4), radius: 8)
                Image(systemName: "plus")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(Theme.backgroundPrimary)
            }
        }
        .accessibilityLabel("Add holding")
    }
}

#if DEBUG
#Preview {
    RootTabView()
        .environment(PreviewState.populated)
        .environment(\.cryptoService, MockCryptoService())
        .preferredColorScheme(.dark)
}
#endif
