//
//  OnboardingView.swift
//  CryptoWallet
//
//  The three-slide intro shown to first-time users. Mirrors the Figma:
//  full-bleed dark canvas, hero illustration, big bold headline, page
//  indicator, "Skip" in the top-right and a yellow circular Next button
//  in the bottom-right.
//
//  Illustrations: the Figma uses bespoke 3D renders. They aren't
//  bundled in this build; if/when they are added to Assets.xcassets
//  with names "onboard1", "onboard2", "onboard3", they'll show up
//  automatically. Until then we fall back to recognisable SF Symbols
//  so the flow demos cleanly.
//

import SwiftUI

struct OnboardingView: View {
    
    /// Closure called when the user finishes (or skips) onboarding.
    let onFinish: () -> Void
    
    @State private var page = 0
    
    private let slides: [Slide] = [
        .init(
            assetName: "onboard1",
            symbolFallback: "bitcoinsign.circle.fill",
            titlePrefix: "Welcome To\n",
            titleAccent: "Foxcrypto"
        ),
        .init(
            assetName: "onboard2",
            symbolFallback: "lock.shield.fill",
            titlePrefix: "Transaction\n",
            titleAccent: "Security"
        ),
        .init(
            assetName: "onboard3",
            symbolFallback: "chart.line.uptrend.xyaxis",
            titlePrefix: "Fast And Reliable\n",
            titleAccent: "Market Updated"
        )
    ]
    
    var body: some View {
        ZStack {
            Theme.backgroundPrimary.ignoresSafeArea()
            
            VStack(spacing: 0) {
                topBar
                
                TabView(selection: $page) {
                    ForEach(slides.indices, id: \.self) { index in
                        slideView(slides[index]).tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                
                bottomBar
                    .padding(.horizontal, 24)
                    .padding(.bottom, 12)
            }
        }
    }
    
    // MARK: - Subviews
    
    private var topBar: some View {
        HStack {
            Spacer()
            Button("Skip", action: onFinish)
                .font(AppFont.bodyMedium(15))
                .foregroundStyle(Theme.accentYellow)
        }
        .padding(.horizontal, 24)
        .padding(.top, 8)
    }
    
    private func slideView(_ slide: Slide) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer(minLength: 24)
            
            // Illustration: real asset if present, SF Symbol otherwise.
            ZStack {
                if UIImage(named: slide.assetName) != nil {
                    Image(slide.assetName)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 280)
                } else {
                    Image(systemName: slide.symbolFallback)
                        .font(.system(size: 140, weight: .light))
                        .foregroundStyle(Theme.accentYellow)
                        .padding(40)
                }
            }
            .frame(maxWidth: .infinity)
            
            Spacer()
            
            // Prefix in white, accent word in yellow — matches the
            // "Welcome To Foxcrypto" treatment from the design.
            (Text(slide.titlePrefix).foregroundStyle(Theme.textPrimary)
                + Text(slide.titleAccent).foregroundStyle(Theme.accentYellow))
                .font(AppFont.display(34))
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
        }
    }
    
    private var bottomBar: some View {
        HStack {
            PageIndicator(pageCount: slides.count, currentPage: page)
            Spacer()
            CircularNextButton(action: advance)
        }
        .padding(.vertical, 16)
    }
    
    // MARK: - Logic
    
    private func advance() {
        if page < slides.count - 1 {
            withAnimation(.easeInOut) { page += 1 }
        } else {
            onFinish()
        }
    }
}

// MARK: - Slide model

private struct Slide {
    let assetName: String
    let symbolFallback: String
    let titlePrefix: String
    let titleAccent: String
}

#Preview {
    OnboardingView(onFinish: {})
}
