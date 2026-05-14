# CryptoWallet — UTS Mobile App Development, Assignment 3

A SwiftUI cryptocurrency wallet app built for UTS Assignment 3 (30%). Users sign up, complete a simulated KYC flow, then track holdings and browse markets with live data from CoinGecko.

The visual design is adapted from the **Foxcrypto** community template by [Nickelfox](https://www.figma.com/design/ZFMQppx0aP6BC6n7CAyMbq/Foxcrypto---Crypto-App--Community-?node-id=0-1&p=f&t=RkRaE6r4m8L9FXj1-0) (Figma Community), used with credit. All Swift code in this project is original.

---

## Target user — "Alex, 24, recent grad"

Alex bought their first crypto last month. They want a clean, branded place to track value as it moves, glance at the rest of the market, and add new positions without learning yet another exchange UI. Existing exchange apps optimise for trading; Alex isn't trading — they're holding.

The app prioritises:
- A balance-front-and-centre home screen — Alex sees their net position before anything else
- Holdings that update live from market prices, no manual refresh
- A friction-light "add a holding" flow that fits how Alex actually thinks about the data ("I bought 0.5 BTC at $40k")

---

## Demo credentials

For the in-class presentation:

```
Email:        test@example.com
Password:     Password1
Verify code:  1368   (any 4 digits work — see AuthService)
```

The signup flow is the smoother demo path because it shows the full user journey: account creation → email verification → KYC document selection → ID upload → selfie → "you're verified" → main app. Each step has a Continue button that is disabled until inputs are valid, so the marker can see input validation in action.

---

## Feature checklist (mapped to brief)

| Brief requirement | Implemented? | Where |
|---|---|---|
| Onboarding | ✅ | `OnboardingView` — 3 swipeable slides matching Figma |
| Authentication | ✅ | `AuthFlowView`, `LoginView`, `SignupView` (simulated, behind protocol) |
| Email verification | ✅ | `EmailVerificationView` — 4-digit boxes, countdown, mock backend |
| KYC flow | ✅ | `KYCFlowView` — country select → document upload → selfie → verified |
| Browse market data | ✅ | `MarketView` with search + favourites filter |
| Coin detail with chart | ✅ | `CoinDetailView` with Apple Charts (1D/7D/30D/1Y) |
| Track holdings | ✅ | `PortfolioView` + `AddHoldingView` |
| Portfolio totals | ✅ | Total value, total cost, P/L shown in the selected display currency |
| Persistence | ✅ | `PortfolioStore`, `LocalAuthService` (UserDefaults + JSON) |
| Settings | ✅ | `SettingsView` — currency, theme, account info, logout |
| Multiple tabs | ✅ | `RootTabView` — custom 4-tab bar with centre + button |

---

## Architecture

Standard MVVM split across three layers:

```
Models       → plain immutable structs (Coin, Holding, Account, KYCProfile)
ViewModels   → @Observable @MainActor, async methods, no UIKit
Views        → SwiftUI only, dark-first theming, single source of truth
Services     → CryptoServiceProtocol + AuthServiceProtocol behind protocols
DTOs         → wire-format types in Models/DTOs, decode → toDomain()
```

Key wiring decisions:

- **`AppState` is the single observable.** Owns currency, theme, holdings, favourites, and the active account. Children read it via `@Environment(AppState.self)`.
- **`MarketViewModel` is shared between Home and Market.** One instance lives in `RootTabView` and is passed down — no duplicate fetches, no out-of-sync price displays.
- **Services are protocol-first.** Every ViewModel takes `any CryptoServiceProtocol` / `any AuthServiceProtocol` so mocks can be injected without changing the call sites. The real `LocalAuthService` and `CryptoService` only differ from their mocks in *what they do*, not *how they're called*.
- **Errors are typed enums.** `CryptoError` and `AuthError` both conform to `LocalizedError` + `Equatable`, so call sites get exhaustive switches and `Phase.failed(.offline) == .failed(.offline)` works.
- **Routing is centralised.** `RootGate` is the single switch that decides which top-level view to show based on auth + KYC state.

---

## Rubric mapping

| Criterion | Where to find it |
|---|---|
| Functional separation | Each layer has a single responsibility — see the architecture diagram above. `PriceFormatter` is a pure formatting type; `PortfolioStore` only persists; ViewModels only orchestrate; views only render. |
| Loose coupling | `CryptoServiceProtocol` and `AuthServiceProtocol` injected via `@Environment` and initialiser. `MockCryptoService` / `MockAuthService` exist as proof. |
| Data modelling | `Coin` and `Holding` are immutable `let`-only structs. `ValuedHolding` is derived purely from `Holding + price`, never persisted. DTOs split from domain types. |
| Type system used to prevent incorrect code | `CryptoError`, `AuthError`, `Currency`, `KYCStatus`, `ChartRange`, `Tab` are all enums. `ValuedHolding` cannot exist without a price. The compiler enforces our invariants. |
| Error handling | Every async service call returns a typed error. `MarketView`, `CoinDetailView`, `LoginView`, `SignupView` all render error UI inline. Validation runs both client- and "server"-side (auth service). |
| Extensibility | Adding a new fiat currency is a single line in `Currency`. Adding a new chart range is a single case in `ChartRange`. Adding a new auth provider is a new conformer to `AuthServiceProtocol`. |
| Idempotency | `ValuedHolding` derivations are pure functions — repeated reads of derived values do not mutate state. |
| Iterative cycles | Three documented loops: (1) MVP wallet → (2) live data + protocol abstraction → (3) Foxcrypto redesign + auth/KYC flow. |
| Greatest difficulty | Sharing `MarketViewModel` between Home and Market without a duplicate refresh — solved by lifting it to `RootTabView` and passing it down. Documented in code comments. |

---

## Iterative cycles

**Cycle 1 — MVP** (Week 9)
- Holdings model, in-memory portfolio totals, manual coin entry by ID.
- Single-tab UI, system fonts, no theming.
- Hardcoded sample data — no network.

**Cycle 2 — Live data + abstractions** (Week 10)
- `CryptoServiceProtocol` introduced. `MockCryptoService` and real `CryptoService`.
- Apple Charts framework integrated into Detail screen.
- Persistence via `PortfolioStore` (UserDefaults).
- Loading / error / empty UI states added everywhere.

**Cycle 3 — Foxcrypto redesign + auth** (Week 11)
- Theme overhauled to match Figma (`#16171D`, `#F5C249`, `#21242D`).
- Onboarding + Welcome + Login + Signup + Email verification screens added.
- KYC flow (4 steps) wired up.
- Custom tab bar with centre yellow + button.
- Home screen rebuilt with gradient blue Total Balance hero card.
- All views restyled to the dark + yellow aesthetic.

---

## Greatest difficulty

The Home screen and Market tab both need to show coin data, and the user expects the same prices on both. Initially each tab created its own `MarketViewModel`, which meant:

1. Switching tabs triggered a fresh fetch
2. Top Coins on Home showed yesterday's prices while Market showed today's
3. Pull-to-refresh on Market didn't update Home

The fix: lift `MarketViewModel` into `RootTabView` and pass it down via `@Bindable` to both `HomeView(marketVM:)` and `MarketView(marketVM:)`. Now:

- One fetch on first launch, both tabs see the result
- Pull-to-refresh on Market updates Home automatically
- Tab switches are instant — no spinner

Code comment in `RootTabView.swift` documents the design choice for the marker.

---

## Tech & dependencies

- iOS 17.0+ (SwiftUI `@Observable`, Apple Charts framework)
- Swift Concurrency (`async`/`await`, `Task` cancellation for debouncing)
- No third-party packages — entire app is Apple-frameworks-only
- Free-tier CoinGecko API (no key needed); rate-limited to ~30 req/min, handled gracefully

---

## Known tradeoffs / future work

- **Real photo upload in KYC.** Currently the upload slots are tap-to-toggle. A full implementation would use `PhotosPicker` (or `UIImagePickerController` bridged) to capture and persist an image. Out of scope for this assignment's rubric.
- **Real backend.** All auth and KYC is local. The protocol abstraction means a future swap to Firebase/Supabase is one new conformer, not a rewrite — but it's flagged here so a marker can ask about it in the demo.
- **News API.** The Home screen's News section uses three hardcoded headlines. Real integration would need a news provider (CoinGecko, NewsAPI, CryptoCompare).
- **USD cost basis in Add Holding.** Holdings are still entered with a USD purchase price, because cost basis is stored internally in USD. The portfolio screen converts that stored cost basis into the selected display currency at render time, but a production app would support entering the original purchase price in the user's chosen fiat currency too.
- **Password security.** Passwords are stored in plaintext in UserDefaults — this is *educational mock only* and is documented as such in `AuthService.swift`. A real app uses Keychain + key derivation.

---

## Credits

- **Visual design:** Foxcrypto template by Nickelfox (Figma Community), used with credit. All Swift code is original.
- **Market data:** [CoinGecko](https://www.coingecko.com/en/api) public API.
- **Font:** Apple SF Pro Rounded (system font; chosen as a free, native alternative to the Figma's Poppins).
- **Sample news images:** [Unsplash](https://unsplash.com).

---

## Repository

GitHub: `https://github.com/Brycekoh/IOS-Assignment-3`
