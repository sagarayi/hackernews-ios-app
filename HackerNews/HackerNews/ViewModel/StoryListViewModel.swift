//
//  StoryListViewModel.swift
//  HackerNews
//
//  Created by Sagar Ayi on 8/20/25.
//

enum State {
    case idle, loading, loaded, erro(Error)
}

protocol StoryListViewModeling {
    var feed: Feed { get }
    var onChange:( (State) -> Void)? { get set }
    func load()
    func loadMoreIfNeeded(currentIndex: Int)
    func item(at row: Int) -> HNItem?
    var count: Int { get }
}

final class StoryListViewModel: StoryListViewModeling {
    private let repo: HNRepository
    private(set) var feed: Feed
    private var ids: [Int] = []
    private var hydrated: [Int: HNItem] = [:]
    private var pageSize: Int = 30
    private var nextIndex: Int = 0
    
    var onChange: ((State) -> Void)?
    var count: Int { nextIndex }
    
    init(repo: HNRepository, feed: Feed) {
        self.repo = repo
        self.feed = feed
    }
    
    func load() {
        Task { [weak self] in
            guard let self = self else {return}
            self.onChange?(.loading)
            do {
                self.ids = try await repo.storyIds(feed: feed)
                self.nextIndex = 0
                try await self.hydrateNextPageIfNeeded()
                self.onChange?(.loaded)
            } catch {
                self.onChange?(.erro(error))
            }
        }
    }
    

    
    func loadMoreIfNeeded(currentIndex: Int) {
//        guard currentIndex >= nextIndex - 5 else  { return }
        Task {
            try await hydrateNextPageIfNeeded()
        }
    }
    
    private func hydrateNextPageIfNeeded() async throws {
        guard nextIndex < ids.count else {return}
        let upper = min(pageSize + nextIndex, ids.count)
        let slice = ids[nextIndex..<upper]
        try await withThrowingTaskGroup(of: (Int, HNItem).self) { group in
            for id in slice {
                group.addTask{
                    let item = try await self.repo.item(id: id)
                    return (id, item)
                }
            }
            
            for try await (id, item) in group {
                hydrated[id] = item
            }
        }
        nextIndex = upper
    }
    
    func item(at row: Int) -> HNItem? {
        guard row < nextIndex else { return nil }
        let id = ids[row]
        return hydrated[id]
    }
    
    
    
    
}
