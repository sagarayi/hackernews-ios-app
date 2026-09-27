//
//  HNError.swift
//  HackerNews
//
//  Typed errors surfaced to the UI with user-readable messages.
//

import Foundation

enum HNError: LocalizedError {
    case invalidResponse
    case http(Int)
    case decodingFailed(String)
    case missingItem(Int)

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "The service sent an unexpected response."
        case .http(let code):
            return "The service responded with an error (\(code))."
        case .decodingFailed(let detail):
            return "Couldn't read the response. (\(detail))"
        case .missingItem(let id):
            return "Item \(id) is no longer available."
        }
    }
}
