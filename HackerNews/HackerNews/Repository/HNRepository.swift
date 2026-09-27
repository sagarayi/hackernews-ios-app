//
//  HNRepository.swift
//  HackerNews
//
//  Created by Sagar Ayi on 8/20/25.
//

// Tabs mirror news.ycombinator.com navigation. Submit is omitted because
// posting requires a logged-in account. "Past" is the site's /front page.
enum Feed: String, CaseIterable {
    case new
    case past
    case comments
    case ask
    case show
    case jobs

    var title: String { rawValue.capitalized }

    var tabIconName: String {
        switch self {
        case .new: return "clock"
        case .past: return "archivebox"
        case .comments: return "text.bubble"
        case .ask: return "questionmark.circle"
        case .show: return "eye"
        case .jobs: return "briefcase"
        }
    }

    /// Site path backing this tab, e.g. "newest" for New.
    var sitePath: String {
        switch self {
        case .new: return "newest"
        case .past: return "front"
        case .comments: return "newcomments"
        case .ask: return "ask"
        case .show: return "show"
        case .jobs: return "jobs"
        }
    }
}

protocol HNRepository {
    func item(id: Int) async throws -> HNItem
}

final class DefaultHNRepository: HNRepository {
    private let apiClient: APIClient
    private let itemCache: ItemCache

    init(apiClient: APIClient = URLSessionAPIClient(), itemCache: ItemCache = MemoryItemCache()) {
        self.itemCache = itemCache
        self.apiClient = apiClient
    }

    func item(id: Int) async throws -> HNItem {
        if let cachedItem = itemCache.item(for: id) { return cachedItem }
        // The endpoint returns a literal `null` for deleted/nonexistent items;
        // decoding an Optional maps that to nil instead of throwing a decode error.
        let item: HNItem? = try await apiClient.get(.item(id: id))
        guard let item else { throw HNError.missingItem(id) }
        itemCache.set(item: item)
        return item
    }
}
