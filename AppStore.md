# App Store submission — HN Reader

## Eligibility checklist

### Done in code
- Neutral display name (**HN Reader** via `CFBundleDisplayName`); target and bundle ID untouched
- No YC logo or wordmark anywhere in UI; section names as nav titles
- In-app About tab: version, unofficial disclaimer, privacy policy, terms
- `PRIVACY.md` + `TERMS.md` in repo — usable as hosted policy URLs
- `PrivacyInfo.xcprivacy`: no tracking, no collected data, no required-reason APIs
- `ITSAppUsesNonExemptEncryption=false` (standard HTTPS only → export-compliant)
- No login, no analytics, no ads, no push, no background modes, no IDFA
- Public frameworks only (UIKit/WebKit/Foundation) — no private API
- HTTPS-only networking, no hardcoded IPs (cellular/IPv6-safe)
- Launch screen present; safe-area Auto Layout on iPhone and iPad
- Real error/empty/loading states everywhere; no dead buttons or placeholders
- Dynamic Type, Reduce Motion, and VoiceOver labels throughout

### Still open
- **1024 app icon** (+dark variant): slots are empty — required for submission
- Screenshots must come from your builds (sizes below)

### You do (Apple Developer account + App Store Connect)
- Enroll in the Apple Developer Program; create the app record (bundle `com.sagarayi.HackerNews`)
- Fill the listing (copy draft below), questionnaires, pricing (Free), availability
- Upload via Xcode (Archive → Validate → Distribute) or TestFlight first

## Listing copy (draft)

- **Name:** HN Reader
- **Subtitle:** Clean Hacker News reader
- **Category:** News (primary)
- **Description:**
  HN Reader is a fast, unofficial client for Hacker News with the classic look: ranked story lists across New, Past, Comments, Ask, Show, and Jobs, in the exact order of the website.

  Tap any story to read it in the built-in reader, jump to the discussion, open the archived copy when one exists, or share it. Pull to refresh, infinite scroll, and full Dynamic Type support throughout.

  Unofficial client. Not affiliated with or endorsed by Y Combinator.
- **Keywords:** hn,tech news,startups,programming,show hn,ask hn,developer news,comments
- **Support URL:** https://github.com/sagarayi/hackernews-ios-app
- **Privacy policy URL:** https://github.com/sagarayi/hackernews-ios-app/blob/main/PRIVACY.md
- **Copyright:** 2026 sagarayi

## Questionnaire answers

- **Privacy:** Data Not Collected (no accounts, analytics, tracking, or third-party SDKs)
- **Encryption:** standard HTTPS networking only (exempt; flag set in Info.plist)
- **Age rating:** expect **17+** — the reader opens arbitrary article URLs (unrestricted web browsing)
- **Content rights:** de-branded UI; story/comment text is third-party UGC shown read-only (no posting, so no moderation tooling required)
- **Demo account:** none needed (no login); no demo mode or hidden features

## Screenshots needed

- iPhone 6.9" (1290×2796) and 6.5" (1242×2688 or 1284×2778) — required
- iPad 13" (2048×2732 or 2064×2752) — required while the app is universal; alternatively restrict to iPhone-only to skip these

## Upload steps

1. Xcode → select **Any iOS Device** → Product → Archive (Release)
2. Distribute → App Store Connect → Validate, then Upload (or TestFlight first)
3. In App Store Connect: complete listing + questionnaires, add screenshots, submit for review
