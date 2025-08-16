//
//  StoryDetailView.swift
//  HackerNews
//
//  Created by Sagar Ayi on 8/15/25.
//

import SwiftUI

struct StoryDetailView: View {
    let story: Story
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(story.title ?? "No title")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                if let urlString = story.url, let url = URL(string: urlString) {
                    Link("Read Article", destination: url)
                        .font(.headline)
                        .foregroundStyle(.blue)
                }
                
                HStack {
                    Text("Score: \(story.score ?? 0)")
                    Text("Comments: \(story.descendants ?? 0)")
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
                
                Divider()
                
                Text("Comments go here. Coming soon...")
                    .foregroundStyle(.gray)
            }
            .padding()
        }
        .navigationTitle("Details")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    StoryDetailView(story: Story(id: 123, by: "someone", descendants: 0, kids: [], score: 3, time: 10, title: "Article title", type: "Article", url: "www.google.com"))
}
