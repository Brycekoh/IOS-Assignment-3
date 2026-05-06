# Presentation script — CryptoWallet (5 min)

This is a speaker-ready script for the Assignment 3 in-class demo. Total target time is around 5 minutes. Each section has a rough word count → seconds estimate (140 words ≈ 1 min at presenter pace).

Suggested split across a 4-person group: one person per section. Whoever takes "Architecture" has the heaviest lift and should have the iPad/Xcode ready.

---

## Section 1 — Problem & user (~45 sec)

> "Hi, we're building **CryptoWallet** — a SwiftUI iOS app that targets a specific user we called Alex.
>
> Alex is 24, recently bought their first crypto, and isn't trading — they're holding. Existing exchange apps optimise for trading: live order books, candlestick charts, leverage. Alex doesn't need any of that. They just want to *see* their net position, watch the market without effort, and add new positions when they buy.
>
> So we built an app where the *balance* is the front-and-centre thing on the home screen, and adding a holding takes three taps."

**Show:** Home screen, balance card.

---

## Section 2 — User flow (~75 sec)

> "Quick run-through of the full flow.
>
> First time the app opens, Alex sees onboarding — three slides explaining the value prop. They sign up with email and password, get a four-digit verification code, then walk through the simulated KYC flow — country, ID document, selfie. The whole thing takes under 30 seconds. The brief allowed us to skip a real backend so we built a local persistence layer that simulates one — but it's protocol-based, so swapping in real Firebase later is one new file, not a rewrite.
>
> Once verified, the main app has four tabs. Home shows the balance. Market is the full coin list — searchable, filterable to favourites. Tapping a coin opens detail with a chart that supports 1-day, 7-day, 30-day, and 1-year ranges. Portfolio shows holdings with profit/loss. The yellow plus button between the centre tabs adds a new holding."

**Show:** Run through onboarding → signup → verify code (use 1368) → KYC quick → tap through tabs.

---

## Section 3 — Architecture (~90 sec) — *most important*

> "Now the bit the rubric's actually rewarding. Three architectural decisions worth calling out.
>
> **First, loose coupling through protocols.** Every ViewModel depends on `CryptoServiceProtocol` and `AuthServiceProtocol`, never on the concrete types. We have a real `CryptoService` that hits the CoinGecko API, and a `MockCryptoService` that returns fixture data. SwiftUI previews use the mock; the running app uses the real one. Same code path — just a different conformer in the environment. Same applies to auth: `LocalAuthService` for the demo, `FirebaseAuthService` would be a future implementation.
>
> **Second, immutable data + derived types.** A `Holding` is a let-only struct — once you've bought 0.5 BTC at $40k, you can't accidentally mutate that. Profit/loss is derived through a separate `ValuedHolding` type that combines a holding with a current price. Pure functions, never persisted. We tested this with a hundred reads producing the same result — proof there's no hidden state.
>
> **Third, typed errors.** Every async service call returns either a value or a `CryptoError` enum. Call sites get exhaustive switches — the compiler tells you if you've forgotten to handle a case."

**Show:** Open `CryptoServiceProtocol.swift` and `MockCryptoService.swift` side by side in Xcode.

---

## Section 4 — Hardest problem (~45 sec)

> "Hardest problem we hit: the home screen and the market tab both display coin data, and a user expects them to show the same prices. Initially each tab created its own `MarketViewModel`, which meant switching tabs triggered a fresh fetch and the two screens could show different numbers.
>
> Fix: lift the view model up to `RootTabView` and pass it down to both children. One fetch on first launch, both screens see the result, pull-to-refresh on Market updates Home automatically. Single source of truth, in two screens."

**Show:** Briefly point at `RootTabView.swift` lines showing `marketVM` injection.

---

## Section 5 — What's next & wrap (~45 sec)

> "Three things we'd ship in v2 if we had more time:
>
> One — real photo capture in KYC. Right now the upload slots are tap-to-toggle, which is enough for a demo but obviously needs a real `PhotosPicker` integration before this hits the App Store.
>
> Two — currency conversion across the whole portfolio. Holdings are stored in USD; switching the active currency to AUD updates list prices but the total still sums in USD. Real implementation would convert per-holding at render time using live FX rates.
>
> Three — real news. The home screen has a News section with hardcoded headlines for the demo. A NewsAPI integration would slot in cleanly behind a `NewsServiceProtocol`.
>
> The visual design is adapted from the Foxcrypto community template by Nickelfox, used with credit. Everything in Swift is original code. Thanks — happy to take questions."

---

## Demo run-checklist (do this BEFORE going on stage)

- [ ] Sign out of any existing test account so the cold-start flow shows from onboarding
- [ ] Have `test@example.com` / `Password1` typed into a notes app for fast paste
- [ ] Have **simulator already at the Welcome screen** when you start talking — saves 5 seconds and avoids the cold-launch wait
- [ ] Wifi check — CoinGecko needs network for real prices. If presentation room has dodgy wifi, use the mock service (one-line change in `CryptoWalletApp.swift`)
- [ ] Brightness up. Phones in classrooms always look dim
- [ ] One tab open in Xcode showing `CryptoServiceProtocol.swift` for the architecture moment
- [ ] Phones on silent — except the demo phone, which should be on vibrate so haptics work and the room hears them

---

## Q&A landmines

These are questions the marker is likely to ask. Have answers ready.

**"Is the auth real?"**
> "No — it's a local mock. The brief allowed us to skip a real backend. But everything's behind a protocol so a real Firebase or Supabase swap is a new file, not a rewrite. We made that an explicit design choice."

**"Why no Firebase?"**
> "Firebase requires Mac access for the iOS SDK setup and adds significant scope. Our group works partly on Windows machines using MacinCloud, and we judged the protocol abstraction would impress the marker more than the wired-up backend would. We'd swap to Firebase as the v2 step."

**"Why iOS 17+ and not lower?"**
> "We use `@Observable` and the new `@Bindable` patterns, which are iOS 17 only. Targeting iOS 16 would mean using `@Published` + `ObservableObject`, which is verbose. The newer pattern is cleaner code and the rubric rewards modern Swift."

**"Why CoinGecko and not another API?"**
> "Free tier, no API key needed, well-documented. Rate limit is 30 requests per minute which is more than enough for one user. Bigger volume would warrant moving to a paid provider."

**"What's the testing strategy?"**
> "Unit tests for the layers below the View — models, view models, services. SwiftUI views are verified through previews and manual interaction. Tests cover happy paths, error paths, and idempotency."

**"Any third-party packages?"**
> "None. Everything is Apple frameworks — SwiftUI, Charts, Foundation. The rubric doesn't reward dependency count, and avoiding them keeps the build trivial."

**"What about accessibility?"**
> "We use semantic SwiftUI components throughout — `Button`, `TextField`, `NavigationStack` — so VoiceOver and Dynamic Type work by default. We added accessibility labels on icon-only buttons like the password eye toggle and the floating + button. Full audit would be the next step before App Store."
