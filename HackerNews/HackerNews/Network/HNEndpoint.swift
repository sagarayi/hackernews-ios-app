//
//  HNEndpoint.swift
//  HackerNews
//
//  Created by Sagar Ayi on 8/19/25.
//

import Foundation

enum HNEndpoint {
    case item(id: Int)

    var url: URL {
        URL(string: "https://hacker-news.firebaseio.com/v0/\(path).json")!
    }

    private var path: String {
        switch self {
        case .item(let id): return "item/\(id)"
        }
    }
}
