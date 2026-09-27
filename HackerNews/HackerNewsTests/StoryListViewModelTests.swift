//
//  StoryListViewModelTests.swift
//  HackerNewsTests
//

import XCTest
@testable import HackerNews

actor MockHNRepository: HNRepository {
    var items: [Int: HNItem] = [:]
    var failingIDs: Set<Int> = []
    private(set) var itemFetchCount = 0

    func configure(ids: [Int], failing: Set<Int> = []) {
        failingIDs = failing
        items = Dictionary(uniqueKeysWithValues: ids.map { id in
            (id, MockHNRepository.makeItem(id: id))
        })
        itemFetchCount = 0
    }

    func setFailing(_ ids: Set<Int>) {
        failingIDs = ids
    }

    func fetchCount() -> Int { itemFetchCount }

    func item(id: Int) async throws -> HNItem {
        itemFetchCount += 1
        if failingIDs.contains(id) { throw URLError(.timedOut) }
        guard let item = items[id] else { throw HNError.missingItem(id) }
        return item
    }

    static func makeItem(id: Int) -> HNItem {
        HNItem(
            id: id,
            isDeleted: nil,
            type: .story,
            by: "user\(id)",
            time: Date().timeIntervalSince1970 - 3600,
            text: nil,
            isDead: nil,
            parent: nil,
            poll: nil,
            kids: nil,
            url: "https://example.com/\(id)",
            score: id * 10,
            title: "Title \(id)",
            parts: nil,
            descendants: id
        )
    }
}

actor MockOrderProvider: StoryOrderProviding {
    var pages: [[Int]] = []
    var hasMoreFlags: [Bool] = []
    var failure: Error?

    func configure(pages: [[Int]], hasMore: [Bool] = [], failure: Error? = nil) {
        self.pages = pages
        self.hasMoreFlags = hasMore
        self.failure = failure
    }

    func storyIds(feed: Feed, page: Int) async throws -> StoryOrderPage {
        if let failure { throw failure }
        let index = page - 1
        guard index < pages.count else { return StoryOrderPage(ids: [], hasMore: false) }
        let more = index < hasMoreFlags.count ? hasMoreFlags[index] : false
        return StoryOrderPage(ids: pages[index], hasMore: more)
    }
}

final class StoryListViewModelTests: XCTestCase {
    private func makeSUT(
        pages: [[Int]],
        hasMore: [Bool] = [],
        failing: Set<Int> = [],
        orderFailure: Error? = nil
    ) async -> (StoryListViewModel, MockHNRepository, MockOrderProvider) {
        let mock = MockHNRepository()
        await mock.configure(ids: Array(Set(pages.flatMap { $0 })), failing: failing)
        let order = MockOrderProvider()
        await order.configure(pages: pages, hasMore: hasMore, failure: orderFailure)
        let viewModel = await StoryListViewModel(repo: mock, orderProvider: order, feed: .new)
        return (viewModel, mock, order)
    }

    func testInitialLoadHydratesFirstSitePage() async {
        let (viewModel, mock, _) = await makeSUT(pages: [Array(1...30), Array(31...50)], hasMore: [true, false])
        await viewModel.load()
        let items = await viewModel.items
        let state = await viewModel.state
        let fetchCount = await mock.fetchCount()
        XCTAssertEqual(items.count, 30)
        XCTAssertEqual(items.map(\.id), Array(1...30))
        XCTAssertEqual(state, .loaded)
        XCTAssertEqual(fetchCount, 30)
    }

    func testOrderMatchesProviderExactly() async {
        let (viewModel, _, _) = await makeSUT(pages: [[7, 2, 9]], hasMore: [false])
        await viewModel.load()
        let items = await viewModel.items
        XCTAssertEqual(items.map(\.id), [7, 2, 9])
    }

    func testLoadMoreIgnoresIndexesBelowThreshold() async {
        let (viewModel, mock, _) = await makeSUT(pages: [Array(1...30)], hasMore: [false])
        await viewModel.load()
        await viewModel.loadMoreIfNeeded(currentIndex: 0)
        await viewModel.loadMoreIfNeeded(currentIndex: 10)
        let fetchCount = await mock.fetchCount()
        let items = await viewModel.items
        XCTAssertEqual(fetchCount, 30)
        XCTAssertEqual(items.count, 30)
    }

    func testPaginationAppendsNextSitePage() async {
        let (viewModel, mock, _) = await makeSUT(
            pages: [Array(1...30), Array(31...60), Array(61...65)],
            hasMore: [true, true, false]
        )
        await viewModel.load()
        await viewModel.loadMoreIfNeeded(currentIndex: 29)
        let items = await viewModel.items
        let state = await viewModel.state
        let fetchCount = await mock.fetchCount()
        XCTAssertEqual(items.count, 60)
        XCTAssertEqual(items.map(\.id), Array(1...60))
        XCTAssertEqual(state, .loaded)
        XCTAssertEqual(fetchCount, 60)
        // Final partial page
        await viewModel.loadMoreIfNeeded(currentIndex: 59)
        let finalItems = await viewModel.items
        let canLoadMore = await viewModel.canLoadMore
        XCTAssertEqual(finalItems.count, 65)
        XCTAssertFalse(canLoadMore)
    }

    func testPartialPageFailureSkipsBadItems() async {
        let (viewModel, _, _) = await makeSUT(pages: [Array(1...30)], hasMore: [false], failing: [5])
        await viewModel.load()
        let items = await viewModel.items
        let state = await viewModel.state
        XCTAssertEqual(items.count, 29)
        XCTAssertFalse(items.map(\.id).contains(5))
        XCTAssertEqual(state, .loaded)
    }

    func testTotalPageFailureEmitsErrorWithoutAdvancing() async {
        let (viewModel, mock, _) = await makeSUT(
            pages: [Array(1...30), Array(31...35)],
            hasMore: [true, false],
            failing: Set(31...35)
        )
        await viewModel.load()
        let loadedItems = await viewModel.items
        XCTAssertEqual(loadedItems.count, 30)

        await viewModel.loadMoreIfNeeded(currentIndex: 29)
        let itemsAfterFailure = await viewModel.items
        let stateAfterFailure = await viewModel.state
        let canLoadMoreAfterFailure = await viewModel.canLoadMore
        XCTAssertEqual(itemsAfterFailure.count, 30)
        if case .error = stateAfterFailure {
            // expected
        } else {
            XCTFail("Expected .error state after total page failure")
        }
        XCTAssertTrue(canLoadMoreAfterFailure)

        // Retry succeeds once failures clear (same site page retried verbatim)
        await mock.setFailing([])
        await viewModel.retryLoadMore()
        let itemsAfterRetry = await viewModel.items
        let stateAfterRetry = await viewModel.state
        XCTAssertEqual(itemsAfterRetry.count, 35)
        XCTAssertEqual(itemsAfterRetry.map(\.id), Array(1...35))
        XCTAssertEqual(stateAfterRetry, .loaded)
    }

    func testOrderFetchFailureEmitsError() async {
        let (viewModel, _, _) = await makeSUT(pages: [], orderFailure: URLError(.notConnectedToInternet))
        await viewModel.load()
        let state = await viewModel.state
        let items = await viewModel.items
        if case .error = state {
            // expected
        } else {
            XCTFail("Expected .error state when the site page fails")
        }
        XCTAssertTrue(items.isEmpty)
    }

    func testScraperPreservesSiteOrder() {
        let html = """
        <html><body><table>
        <tr class="athing" id="511"><td><span class="rank">1.</span></td></tr>
        <tr><td class="subtext">score etc</td></tr>
        <tr class="athing" id="207"><td><span class="rank">2.</span></td></tr>
        <tr><td class="subtext">score etc</td></tr>
        <tr class="athing" id="933"><td><span class="rank">3.</span></td></tr>
        </table><a class="morelink" href="news?p=2" rel="next">More</a></body></html>
        """
        let page = HNHTMLScraper.parse(html: html)
        XCTAssertEqual(page.ids, [511, 207, 933])
        XCTAssertTrue(page.hasMore)

        let lastPage = HNHTMLScraper.parse(html: "<html><body>No more rows</body></html>")
        XCTAssertTrue(lastPage.ids.isEmpty)
        XCTAssertFalse(lastPage.hasMore)
    }
}
