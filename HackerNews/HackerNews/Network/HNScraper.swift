//
//  HNScraper.swift
//  HackerNews
//
//  Story ordering scraped from news.ycombinator.com itself: each tab's page
//  HTML lists stories in display order (`<tr class="athing" id="…">` rows),
//  with a "More" link while further pages exist. Item bodies still come
//  from the Firebase API; only the order (and pagination) comes from here.
//

import Foundation

struct StoryOrderPage {
    let ids: [Int]
    let hasMore: Bool
}

protocol StoryOrderProviding {
    func storyIds(feed: Feed, page: Int) async throws -> StoryOrderPage
}

final class HNHTMLScraper: StoryOrderProviding {
    private static let base = "https://news.ycombinator.com"
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func storyIds(feed: Feed, page: Int) async throws -> StoryOrderPage {
        var components = URLComponents(string: Self.base + "/" + feed.sitePath)!
        if page > 1 {
            components.queryItems = [URLQueryItem(name: "p", value: "\(page)")]
        }
        guard let url = components.url else { throw HNError.invalidResponse }
        var request = URLRequest(url: url)
        request.timeoutInterval = 15
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw HNError.invalidResponse }
        guard (200..<300).contains(http.statusCode) else { throw HNError.http(http.statusCode) }
        guard let html = String(data: data, encoding: .utf8) else { throw HNError.invalidResponse }
        return Self.parse(html: html)
    }

    /// Row order in the HTML *is* display order; rank is positional.
    /// Story rows carry extra classes (`class="athing submission"`), so the
    /// class attribute is matched as containing the token, not equal to it.
    static func parse(html: String) -> StoryOrderPage {
        var ids: [Int] = []
        let pattern = #"<tr[^>]*\bathing\b[^>]*\bid=["'](\d+)"#
        if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
            let range = NSRange(html.startIndex..., in: html)
            for match in regex.matches(in: html, options: [], range: range) {
                if let idRange = Range(match.range(at: 1), in: html),
                   let id = Int(html[idRange]) {
                    ids.append(id)
                }
            }
        }
        let hasMore = html.range(of: "morelink") != nil
        return StoryOrderPage(ids: ids, hasMore: hasMore)
    }
}
