//
//  HNRepository.swift
//  HackerNews
//
//  Created by Sagar Ayi on 8/20/25.
//

enum Feed: CaseIterable {
    case top
}

protocol HNRepository {
    func storyIds(feed: Feed) async throws -> [Int]
    func item(id: Int) async throws -> HNItem
}


final class DefaultHNRepository: HNRepository {
    private let apiClient: APIClient
    private let itemCache: ItemCache
    
    init(apiClient: APIClient = URLSessionAPIClient(), itemCache: ItemCache = MemoryItemCache()) {
        self.itemCache = itemCache
        self.apiClient = apiClient
    }
    
    func storyIds(feed: Feed) async throws -> [Int] {
        switch feed {
        case .top:
            return try await apiClient.get(.topStories) as [Int]
        }
    }
    
    func item(id: Int) async throws -> HNItem {
        if let cachedItem = itemCache.item(for: id) { return cachedItem }
        let item = try await apiClient.get(.item(id: id)) as HNItem
        itemCache.set(item: item)
        return item
    }
}
