//
//  APIClient.swift
//  HackerNews
//
//  Created by Sagar Ayi on 8/19/25.
//

import Foundation

protocol APIClient {
    func get<T: Decodable>(_ endpoint: HNEndpoint) async throws -> T
}

final class URLSessionAPIClient: APIClient {
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func get<T: Decodable>(_ endpoint: HNEndpoint) async throws -> T {
        var request = URLRequest(url: endpoint.url)
        // Use the protocol cache policy (was: reloadIgnoringLocalCacheData),
        // so repeat launches and revisits can be served from URLCache.
        request.cachePolicy = .useProtocolCachePolicy
        request.timeoutInterval = 15

        let (data, response) = try await session.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw HNError.invalidResponse
        }
        guard (200..<300).contains(http.statusCode) else {
            throw HNError.http(http.statusCode)
        }

        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw HNError.decodingFailed(String(describing: error))
        }
    }
}
