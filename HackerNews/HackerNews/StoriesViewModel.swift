//
//  StoriesViewModel.swift
//  HackerNews
//
//  Created by Sagar Ayi on 8/15/25.
//

import Foundation

@MainActor
class StoriesViewModel: ObservableObject {
    @Published var stories: [Story] = []
    
    func fetchTopStories() async {
        do {
            guard let idsURL = URL(string: "https://hacker-news.firebaseio.com/v0/topstories.json") else { return }
            let (data, error) = try await URLSession.shared.data(from: idsURL)
            let ids = try JSONDecoder().decode([Int].self, from: data)
            
            let top10 = Array(ids.prefix(10))
            
            var fetchedStories: [Story] = []
            for id in top10 {
                guard let itemURL = URL(string: "https://hacker-news.firebaseio.com/v0/item/\(id).json") else { return }
                let (itemData, error) = try await URLSession.shared.data(from: itemURL)
                let story = try JSONDecoder().decode(Story.self, from: itemData)
                fetchedStories.append(story)
            }
            
            self.stories = fetchedStories
            
        } catch {
            print("Error : \(error)")
        }
    }
}
