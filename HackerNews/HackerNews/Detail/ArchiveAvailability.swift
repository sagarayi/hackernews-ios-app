//
//  ArchiveAvailability.swift
//  HackerNews
//
//  Checks archive.today (the archive.is service) for a snapshot of a URL and
//  returns the newest snapshot address, or nil when there is none.
//  Fail-closed: any error hides the archive button.
//

import Foundation

final class ArchiveAvailability {
    private var cache: [String: URL?] = [:]
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func latestSnapshot(for target: URL) async -> URL? {
        let key = target.absoluteString
        if let hit = cache[key] { return hit }
        let result = await fetchSnapshot(for: target)
        cache[key] = result
        return result
    }

    private func fetchSnapshot(for target: URL) async -> URL? {
        guard target.scheme == "http" || target.scheme == "https" else { return nil }
        // /newest/ redirects to the latest snapshot when one exists and
        // serves the archive form page otherwise.
        guard let probe = URL(string: "https://archive.ph/newest/" + target.absoluteString) else { return nil }
        var request = URLRequest(url: probe)
        request.cachePolicy = .reloadIgnoringLocalCacheData
        request.timeoutInterval = 10
        request.setValue(
            "Mozilla/5.0 (iPhone; CPU iPhone OS 18_5 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.5 Mobile/15E148 Safari/604.1",
            forHTTPHeaderField: "User-Agent"
        )
        do {
            let (_, response) = try await session.data(for: request)
            if Task.isCancelled { return nil }
            guard let http = response as? HTTPURLResponse,
                  (200..<300).contains(http.statusCode),
                  let finalURL = http.url,
                  finalURL != probe else { return nil }
            // Snapshot addresses embed the original URL; a miss serves the
            // archive form page instead of redirecting.
            guard let host = target.host, finalURL.absoluteString.contains(host) else { return nil }
            return finalURL
        } catch {
            return nil
        }
    }
}
