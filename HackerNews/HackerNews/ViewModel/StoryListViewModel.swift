//
//  StoryListViewModel.swift
//  HackerNews
//
//  Created by Sagar Ayi on 8/20/25.
//

import Foundation
import os

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
    var feedTitle: String { get }
    var onChange: (@MainActor (StoryListState) -> Void)? { get set }
    var onLoadingMoreChanged: (@MainActor (Bool) -> Void)? { get set }
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
    var feedTitle: String { feed.title }
    var onChange: (@MainActor (StoryListState) -> Void)?
    var onLoadingMoreChanged: (@MainActor (Bool) -> Void)?

    private let repo: HNRepository
    private let orderProvider: StoryOrderProviding
    private let feed: Feed

    private var itemsById: [Int: HNItem] = [:]
    private var nextPageURL: URL?
    private var hasMorePages = true
    private var isLoadingPage = false
    private var nextAutoRetryDate = Date.distantPast
    private var consecutiveFailures = 0
    private var autoRetryTask: Task<Void, Never>?
    private var autoRetryCount = 0
    private let maxAutoRetries = 3
    private let log = Logger(subsystem: "com.sagarayi.HackerNews", category: "pagination")

    private let threshold = 6
    private let hydrationConcurrency = 4
    private let interBatchDelay: UInt64
    private let baseRetryCooldown: TimeInterval = 5
    private let maxRetryCooldown: TimeInterval = 60

    init(repo: HNRepository, orderProvider: StoryOrderProviding = HNHTMLScraper(), feed: Feed, batchDelay: UInt64 = 250_000_000) {
        self.repo = repo
        self.orderProvider = orderProvider
        self.feed = feed
        self.interBatchDelay = batchDelay
    }

    // MARK: - Initial load / refresh

    /// Loads site page 1. Old content stays on screen until the new page is
    /// ready, so pull-to-refresh never flashes empty.
    func load() async {
        guard state != .loading else { return }
        cancelAutoRetry()
        state = .loading
        emit()
        log.debug("initial load feed=\(self.feed.rawValue, privacy: .public)")
        do {
            let page = try await orderProvider.storyIds(feed: feed)
            try Task.checkCancellation()
            let (pageItems, pageError) = try await hydratePage(page.ids[...])
            try Task.checkCancellation()
            if pageItems.isEmpty {
                let message = errorMessage(for: pageError ?? HNError.invalidResponse)
                if items.isEmpty {
                    state = .error(message)
                    scheduleAutoRetry(reloadingInitial: true)
                } else {
                    state = .loaded
                }
            } else {
                items = pageItems
                itemsById = Dictionary(uniqueKeysWithValues: pageItems.map { ($0.id, $0) })
                if feed == .comments {
                    await fetchParents(for: pageItems)
                }
                nextPageURL = page.moreURL
                hasMorePages = page.hasMore
                consecutiveFailures = 0
                cancelAutoRetry()
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
        guard let moreURL = nextPageURL else { return }
        isLoadingPage = true
        onLoadingMoreChanged?(true)
        defer {
            isLoadingPage = false
            onLoadingMoreChanged?(false)
        }
        log.debug("loadMore more=\(moreURL.absoluteString, privacy: .public) loaded=\(self.items.count)")

        do {
            let page = try await orderProvider.storyIds(moreURL: moreURL)
            let (pageItems, pageError) = try await hydratePage(page.ids[...])
            log.debug("site page returned \(page.ids.count) ids hasMore=\(page.hasMore), hydrated \(pageItems.count)")

            guard !pageItems.isEmpty else {
                if page.ids.isEmpty {
                    // The site returned no rows — a bad/blocked page, not the
                    // end of the feed. Never trust it as final: don't advance,
                    // and keep pagination retryable instead of stalling it.
                    noteFailure()
                    log.error("site page contained zero rows")
                    state = .error("The site returned an empty page. Pull to refresh or tap Retry.")
                    scheduleAutoRetry(reloadingInitial: false)
                    emit()
                } else if let pageError {
                    // Typically a 429/network failure: back off so continued
                    // scrolling doesn't hammer the API. Explicit Retry
                    // bypasses this cooldown.
                    noteFailure()
                    state = .error(errorMessage(for: pageError))
                    scheduleAutoRetry(reloadingInitial: false)
                    emit()
                } else {
                    // Every row was deleted: skip the page so scrolling
                    // never stalls on unloadable rows.
                    nextPageURL = page.moreURL
                    hasMorePages = page.hasMore
                    consecutiveFailures = 0
                    cancelAutoRetry()
                    state = .loaded
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
            log.debug("appended \(fresh.count) rows, total \(self.items.count)")
            nextPageURL = page.moreURL
            hasMorePages = page.hasMore
            consecutiveFailures = 0
            cancelAutoRetry()
            state = .loaded
            emit()
        } catch is CancellationError {
            // Ignored.
        } catch {
            noteFailure()
            state = .error(errorMessage(for: error))
            scheduleAutoRetry(reloadingInitial: false)
            emit()
        }
    }

    func retryLoadMore() async {
        // Explicit user action bypasses the post-failure cooldown.
        nextAutoRetryDate = .distantPast
        cancelAutoRetry()
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
        // Bounded concurrency plus pacing: firing a full page of ~30 item
        // requests at once gets the API to answer 429. Small batches with
        // a short pause between them stay well under the limit.
        for (batchIndex, start) in stride(from: 0, to: indexed.count, by: hydrationConcurrency).enumerated() {
            if batchIndex > 0 {
                try await Task.sleep(nanoseconds: interBatchDelay)
            }
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
        for (batchIndex, start) in stride(from: 0, to: missing.count, by: hydrationConcurrency).enumerated() {
            if batchIndex > 0 {
                try? await Task.sleep(nanoseconds: interBatchDelay)
            }
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

    /// Exponential backoff (5s, doubling to a 60s cap) across consecutive
    /// failures so a struggling API isn't hammered by continued scrolling.
    /// Reset on success; explicit Retry bypasses the resulting cooldown.
    private func noteFailure() {
        let delay = min(baseRetryCooldown * pow(2.0, Double(consecutiveFailures)), maxRetryCooldown)
        consecutiveFailures += 1
        nextAutoRetryDate = Date().addingTimeInterval(delay)
    }

    /// Schedules one automatic retry after the backoff expires, so a failed
    /// page recovers on its own while the user keeps reading. Capped at
    /// `maxAutoRetries`; manual Retry and refresh take precedence by
    /// cancelling any pending attempt.
    private func scheduleAutoRetry(reloadingInitial: Bool) {
        guard autoRetryCount < maxAutoRetries else { return }
        autoRetryCount += 1
        autoRetryTask?.cancel()
        autoRetryTask = Task { [weak self] in
            guard let self else { return }
            let wait = max(0, self.nextAutoRetryDate.timeIntervalSinceNow) + 0.5
            do {
                try await Task.sleep(nanoseconds: UInt64(wait * 1_000_000_000))
            } catch {
                return
            }
            guard !Task.isCancelled else { return }
            if reloadingInitial {
                await self.load()
            } else {
                await self.retryLoadMore()
            }
        }
    }

    private func cancelAutoRetry() {
        autoRetryCount = 0
        autoRetryTask?.cancel()
        autoRetryTask = nil
    }

    private func errorMessage(for error: Error) -> String {
        let message = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        log.error("request failed: \(message, privacy: .public)")
        return message
    }

    private func emit() {
        onChange?(state)
    }
}
