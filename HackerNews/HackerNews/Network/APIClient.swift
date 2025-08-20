//
//  APIClient.swift
//  HackerNews
//
//  Created by Sagar Ayi on 8/19/25.
//

import Foundation

protocol APIClient {
    func get<T:Decodable>(_ endpoint: HNEndpoint) async throws -> T
}


final class URLSessionAPIClient: APIClient {
    private let urlSession = URLSession.shared
    
    func get<T: Decodable>(_ endpoint: HNEndpoint) async throws -> T {
        var request = URLRequest(url: endpoint.url)
        request.cachePolicy = .reloadIgnoringLocalCacheData
        let (data, resp) = try await urlSession.data(for: request)
        guard let httpResponse = resp as? HTTPURLResponse, (200..<300).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }
        return try JSONDecoder().decode(T.self, from: data)
    }
    
}
