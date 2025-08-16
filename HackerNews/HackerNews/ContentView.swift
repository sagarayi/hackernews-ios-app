//
//  ContentView.swift
//  HackerNews
//
//  Created by Sagar Ayi on 8/15/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject var vm = StoriesViewModel()
    
    var body: some View {
        NavigationView {
            List(vm.stories) { story in
                VStack(alignment: .leading) {
                    Text(story.title ?? "No title")
                        .font(.headline)
                    Text("by: \(story.by ?? "Unknown") • \(story.score ?? 0) points")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Top Stories")
        }
        .task {
            await vm.fetchTopStories()
        }
    }
}

#Preview {
    ContentView()
}
