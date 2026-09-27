//
//  HNItem+Display.swift
//  HackerNews
//
//  Presentation helpers: relative timestamps, clean host names,
//  and plain-text comment bodies (the API returns comment HTML).
//

import Foundation

extension HNItem {
    /// "3 hours ago"-style relative timestamp, or nil when `time` is missing.
    var timeAgoDisplay: String? {
        guard let time, time > 0 else { return nil }
        let date = Date(timeIntervalSince1970: time)
        return Self.relativeFormatter.localizedString(for: date, relativeTo: Date())
    }

    /// Host of the story URL without a "www." prefix, e.g. "example.com".
    var domainHost: String? {
        guard let url, let host = URL(string: url)?.host, !host.isEmpty else { return nil }
        return host.hasPrefix("www.") ? String(host.dropFirst(4)) : host
    }

    /// Comment `text` with tags and entities stripped for list display.
    var plainText: String? {
        guard let text, !text.isEmpty else { return nil }
        var stripped = text.replacingOccurrences(of: "(?i)<p[^>]*>", with: "\n\n", options: .regularExpression)
        stripped = stripped.replacingOccurrences(of: "(?i)<br[^>]*>", with: "\n", options: .regularExpression)
        stripped = stripped.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
        for (entity, character) in Self.htmlEntities {
            stripped = stripped.replacingOccurrences(of: entity, with: character)
        }
        stripped = stripped.replacingOccurrences(of: "[ \\t]+", with: " ", options: .regularExpression)
        stripped = stripped.replacingOccurrences(of: "\\n[ \\t]*\\n[ \\t]*\\n+", with: "\n\n", options: .regularExpression)
        return stripped.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static let relativeFormatter: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter
    }()

    private static let htmlEntities: [(String, String)] = [
        ("&amp;", "&"),
        ("&lt;", "<"),
        ("&gt;", ">"),
        ("&quot;", "\""),
        ("&#x27;", "'"),
        ("&#39;", "'"),
        ("&#x2F;", "/"),
        ("&nbsp;", " "),
    ]
}
