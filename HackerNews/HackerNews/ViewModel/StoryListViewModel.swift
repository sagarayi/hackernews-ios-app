//
//  StoryListViewModel.swift
//  HackerNews
//
//  Created by Sagar Ayi on 8/20/25.
//

import Foundation

enum StoryListState: Equatable {
    case idle
    case loading
    case loaded
    case error(String)
}

@MainActor
protocol StoryListViewModeling: AnyObject {
    var state: StoryListState { get }
    var items: [HNItem] { get }
    var onChange: (@MainActor (StoryListState) -> Void)? { get set }
    func load() async
    func refresh() async
    func loadMoreIfNeeded(currentIndex: Int) async
    func retryLoadMore() async
    func item(for id: Int) -> HNItem?
    var canLoadMore: Bool { get }
}

/// List order always comes from the website's own pages (via
/// `StoryOrderProviding`), so rows match news.ycombinator.com exactly.
/// Item bodies are then hydrated through the Firebase API.
@MainActor
final class StoryListViewModel: StoryListViewModeling {
    private(set) var state: StoryListState = .idle
    private(set) var items: [HNItem] = []
    var onChange: (@MainActor (StoryListState) -> Void)?

    private let repo: HNRepository
    private let orderProvider: StoryOrderProviding
    private let feed: Feed

    private var itemsById: [Int: HNItem] = [:]
    private var nextPage = 1
    private var hasMorePages = true
    private var isLoadingPage = false
    private var nextAutoRetryDate = Date.distantPast

    private let threshold = 6
    private let hydrationConcurrency = 8
    private let retryCooldown: TimeInterval = 5

    init(repo: HNRepository, orderProvider: StoryOrderProviding = HNHTMLScraper(), feed: Feed) {
        self.repo = repo
        self.orderProvider = orderProvider
        self.feed = feed
    }

    // MARK: - Initial load / refresh

    /// Loads site page 1. Old content stays on screen until the new page is
    /// ready, so pull-to-refresh never flashes empty.
    func load() async {
        guard state != .loading else { return }
        state = .loading
        emit()
        do {
            let page = try await orderProvider.storyIds(feed: feed, page: 1)
            try Task.checkCancellation()
            let (pageItems, pageError) = try await hydratePage(page.ids[...])
            try Task.checkCancellation()
            if pageItems.isEmpty {
                let message = errorMessage(for: pageError ?? HNError.invalidResponse)
                state = items.isEmpty ? .error(message) : .loaded
            } else {
                items = pageItems
                itemsById = Dictionary(uniqueKeysWithValues: pageItems.map { ($0.id, $0) })
                if feed == .comments {
                    await fetchParents(for: pageItems)
                }
                nextPage = 2
                hasMorePages = page.hasMore
                state = .loaded
            }
            emit()
        } catch is CancellationError {
            // Caller went away; leave state untouched.
        } catch {
            state = items.isEmpty ? .error(errorMessage(for: error)) : .loaded
            emit()
        }
    }

    func refresh() async {
        await load()
    }

    // MARK: - Pagination

    /// Loads the site's next "More" page. Page numbers only advance on
    /// success, so a failed page is retried verbatim and order never drifts.
    func loadMoreIfNeeded(currentIndex: Int) async {
        guard !isLoadingPage,
              state != .loading,
              hasMorePages,
              Date() >= nextAutoRetryDate,
              currentIndex >= items.count - threshold else { return }
        isLoadingPage = true
        defer { isLoadingPage = false }

        do {
            let page = try await orderProvider.storyIds(feed: feed, page: nextPage)
            let (pageItems, pageError) = try await hydratePage(page.ids[...])

            guard !pageItems.isEmpty else {
                if page.ids.isEmpty || pageError == nil {
                    // Dead page (everything deleted) or truly empty: skip it
                    // so scrolling never stalls on an unloadable page.
                    nextPage += 1
                    hasMorePages = page.hasMore
                    state = .loaded
                    emit()
                } else {
                    // Typically a 429/network failure: back off so continued
                    // scrolling doesn't hammer the API. Explicit Retry
                    // bypasses this cooldown.
                    nextAutoRetryDate = Date().addingTimeInterval(retryCooldown)
                    state = .error(errorMessage(for: pageError!))
                    emit()
                }
                return
            }

            // Dedupe guards against a refresh racing an in-flight page fetch;
            // diffable snapshots cannot contain duplicate identifiers.
            let fresh = pageItems.filter { itemsById[$0.id] == nil }
            items.append(contentsOf: fresh)
            for item in fresh { itemsById[item.id] = item }
            if feed == .comments {
                await fetchParents(for: fresh)
            }
            nextPage += 1
            hasMorePages = page.hasMore
            state = .loaded
            emit()
        } catch is CancellationError {
            // Ignored.
        } catch {
            nextAutoRetryDate = Date().addingTimeInterval(retryCooldown)
            state = .error(errorMessage(for: error))
            emit()
        }
    }

    func retryLoadMore() async {
        // Explicit user action bypasses the post-failure cooldown.
        nextAutoRetryDate = .distantPast
        await loadMoreIfNeeded(currentIndex: max(0, items.count - 1))
    }

    // MARK: - Lookup

    func item(for id: Int) -> HNItem? {
        itemsById[id]
    }

    var canLoadMore: Bool {
        !isLoadingPage && state != .loading && hasMorePages
    }

    // MARK: - Private

    /// Hydrates ids concurrently, preserving the site's order. Deleted items
    /// are skipped; the first real failure is reported alongside whatever
    /// succeeded so callers can tolerate partial pages.
    private func hydratePage(_ slice: ArraySlice<Int>) async throws -> (items: [HNItem], error: Error?) {
        let indexed = Array(slice.enumerated())
        let repo = self.repo
        var collected: [(Int, HNItem?, Error?)] = []
        collected.reserveCapacity(indexed.count)
        // Bounded concurrency: firing a full page of ~30 item requests at
        // once gets the API to answer 429. Batches of 8 stay well under it.
        for start in stride(from: 0, to: indexed.count, by: hydrationConcurrency) {
            try Task.checkCancellation()
            let end = min(start + hydrationConcurrency, indexed.count)
            let chunk = indexed[start..<end]
            let chunkResults = await withTaskGroup(of: (Int, HNItem?, Error?).self) { group in
                for (offset, id) in chunk {
                    group.addTask {
                        do {
                            let item = try await repo.item(id: id)
                            return (offset, item, nil)
                        } catch {
                            if case HNError.missingItem = error {
                                return (offset, nil, nil)
                            }
                            return (offset, nil, error)
                        }
                    }
                }
                var out: [(Int, HNItem?, Error?)] = []
                out.reserveCapacity(chunk.count)
                for await result in group { out.append(result) }
                return out
            }
            collected.append(contentsOf: chunkResults)
        }
        let sorted = collected.sorted { $0.0 < $1.0 }
        return (sorted.compactMap { $0.1 }, sorted.compactMap { $0.2 }.first)
    }

    /// Comments reference their story via `parent`. Missing parents are
    /// fetched so the list can show "on: <story title>" with no per-cell
    /// requests. Parents are stashed in `itemsById`, never in `items`.
    private func fetchParents(for comments: [HNItem]) async {
        let missing = Array(Set(comments.compactMap(\.parent)).subtracting(Set(itemsById.keys)))
        guard !missing.isEmpty else { return }
        let repo = self.repo
        for start in stride(from: 0, to: missing.count, by: hydrationConcurrency) {
            if Task.isCancelled { return }
            let end = min(start + hydrationConcurrency, missing.count)
            let chunk = missing[start..<end]
            let fetched = await withTaskGroup(of: HNItem?.self) { group in
                for id in chunk {
                    group.addTask {
                        do {
                            return try await repo.item(id: id)
                        } catch {
                            return nil
                        }
                    }
                }
                var collected: [HNItem] = []
                for await parent in group {
                    if let parent { collected.append(parent) }
                }
                return collected
            }
            for parent in fetched { itemsById[parent.id] = parent }
        }
    }

    private func errorMessage(for error: Error) -> String {
        (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
    }

    private func emit() {
        onChange?(state)
    }
}
