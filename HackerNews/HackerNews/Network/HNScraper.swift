//
//  HNScraper.swift
//  HackerNews
//
//  Story ordering scraped from news.ycombinator.com itself: each tab's page
//  HTML lists stories in display order (`<tr class="athing …" id="…">` rows).
//  Pagination follows the site's own "More" link (a `next` cursor), because a
//  bare `?p=N` is ignored by the site and would repeat page 1 forever.
//  Item bodies still come from the Firebase API; only order comes from here.
//

import Foundation
import os

struct StoryOrderPage {
    let ids: [Int]
    let moreURL: URL?
    var hasMore: Bool { moreURL != nil }
}

protocol StoryOrderProviding {
    /// First page of a feed, e.g. `/newest`.
    func storyIds(feed: Feed) async throws -> StoryOrderPage
    /// The page behind a previously returned `moreURL`.
    func storyIds(moreURL: URL) async throws -> StoryOrderPage
}

final class HNHTMLScraper: StoryOrderProviding {
    private static let base = "https://news.ycombinator.com"
    private static let log = Logger(subsystem: "com.sagarayi.HackerNews", category: "scraper")
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func storyIds(feed: Feed) async throws -> StoryOrderPage {
        guard let url = URL(string: Self.base + "/" + feed.sitePath) else { throw HNError.invalidResponse }
        return try await fetchPage(url)
    }

    func storyIds(moreURL: URL) async throws -> StoryOrderPage {
        return try await fetchPage(moreURL)
    }

    private func fetchPage(_ url: URL) async throws -> StoryOrderPage {
        Self.log.debug("fetching \(url.absoluteString, privacy: .public)")
        var request = URLRequest(url: url)
        request.timeoutInterval = 15
        request.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 18_5 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.5 Mobile/15E148 Safari/604.1", forHTTPHeaderField: "User-Agent")
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw HNError.invalidResponse }
        guard (200..<300).contains(http.statusCode) else { throw HNError.http(http.statusCode) }
        guard let html = String(data: data, encoding: .utf8) else { throw HNError.invalidResponse }
        let result = Self.parse(html: html, baseURL: url)
        Self.log.debug("parsed \(result.ids.count) ids hasMore=\(result.hasMore)")
        return result
    }

    /// Row order in the HTML *is* display order; rank is positional.
    /// Story rows carry extra classes (`class="athing submission"`), so the
    /// class attribute is matched as containing the token, not equal to it.
    static func parse(html: String, baseURL: URL) -> StoryOrderPage {
        var ids: [Int] = []
        let rowPattern = #"<tr[^>]*\bathing\b[^>]*\bid=["'](\d+)"#
        if let regex = try? NSRegularExpression(pattern: rowPattern, options: []) {
            let range = NSRange(html.startIndex..., in: html)
            for match in regex.matches(in: html, options: [], range: range) {
                if let idRange = Range(match.range(at: 1), in: html),
                   let id = Int(html[idRange]) {
                    ids.append(id)
                }
            }
        }
        return StoryOrderPage(ids: ids, moreURL: moreLink(in: html, baseURL: baseURL))
    }

    /// The More anchor varies attribute order (`href` may precede `class`),
    /// so the tag is matched first and its href extracted second. The href
    /// carries an HTML-escaped cursor (`?next=…&amp;n=…`) that must be
    /// unescaped before resolving.
    private static func moreLink(in html: String, baseURL: URL) -> URL? {
        let fullRange = NSRange(html.startIndex..., in: html)
        guard let tagRegex = try? NSRegularExpression(pattern: #"<a[^>]*\bmorelink\b[^>]*>"#, options: []),
              let tagMatch = tagRegex.matches(in: html, options: [], range: fullRange).first,
              let tagRange = Range(tagMatch.range, in: html) else { return nil }
        let tag = String(html[tagRange])
        guard let hrefRegex = try? NSRegularExpression(pattern: #"href=["']([^"']+)"#, options: []),
              let hrefMatch = hrefRegex.matches(in: tag, options: [], range: NSRange(tag.startIndex..., in: tag)).first,
              let hrefRange = Range(hrefMatch.range(at: 1), in: tag) else { return nil }
        let href = String(tag[hrefRange]).replacingOccurrences(of: "&amp;", with: "&")
        return URL(string: href, relativeTo: baseURL)?.absoluteURL
    }
}
