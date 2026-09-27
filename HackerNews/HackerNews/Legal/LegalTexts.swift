//
//  LegalTexts.swift
//  HackerNews
//
//  Privacy policy and terms embedded for in-app display (Settings-free:
//  reachable from the info button). Mirrors PRIVACY.md / TERMS.md.
//

enum LegalTexts {
    static let privacyPolicy = """
    PRIVACY POLICY — HN READER
    Last updated: September 27, 2026

    HN Reader is an unofficial Hacker News client. Your privacy matters: the app collects no personal data of any kind.

    DATA NOT COLLECTED
    No accounts, sign-in, or user profiles. No analytics, crash reporting SDKs, or advertising identifiers. No tracking of any kind. Nothing you read or tap is recorded, stored, or transmitted anywhere except as described below.

    NETWORK REQUESTS
    To show you stories, your device directly fetches public content from the Firebase Hacker News API (story and comment data), news.ycombinator.com (story ordering), and archive.today (archived copies, on demand). These are standard content requests containing no personal information, and each service operates under its own privacy policy. Links you share leave the app through the iOS share sheet under your control.

    CHILDREN'S PRIVACY
    Because no data is collected from anyone, no data is collected from children under 13 either.

    CHANGES
    Material changes will be posted with a new revision date.

    CONTACT
    https://github.com/sagarayi/hackernews-ios-app
    """

    static let termsAndConditions = """
    TERMS & CONDITIONS — HN READER
    Last updated: September 27, 2026

    1. WHAT THIS IS
    HN Reader is an unofficial, third-party client for browsing Hacker News. It is not affiliated with, sponsored, or endorsed by Y Combinator. Content belongs to its respective authors.

    2. ACCEPTABLE USE
    Use the app for personal, non-commercial reading. Do not misuse the app or the underlying public APIs — scraping aggressively, circumventing rate limits, or misrepresenting retrieved content violates these terms.

    3. CONTENT
    Stories, comments, articles, and archived copies are third-party content. We do not create, review, or endorse it, and we are not responsible for its accuracy, availability, or legality.

    4. NO WARRANTY
    The app is provided "as is" without warranties of any kind. We do not guarantee uninterrupted or error-free operation.

    5. LIABILITY
    To the maximum extent permitted by law, we are not liable for any damages arising from your use of the app.

    6. CHANGES
    We may update these terms; continued use after changes take effect constitutes acceptance.

    7. CONTACT
    https://github.com/sagarayi/hackernews-ios-app
    """
}
