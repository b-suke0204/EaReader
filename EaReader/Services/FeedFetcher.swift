//
//  FeedFetcher.swift
//  EaReader
//
//  Created by Eisuke Nomoto on 2026/08/09.
//

import Foundation
import Combine

enum FeedFetchError: Error {
    case invalidResponse  // 無効な応答
    case notAFeed  // Feedではないとき
    case decodingFailed  // デコード失敗
}

enum FeedFetcher {
    private static let feedUserAgent = "SearchRSS/1.0 (iOS; +https://example.com)"
    private static let browserUserAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS like Mac OS X) SearchRSS/1.0"
    
    // 指定したURLを取得し、RSS/Atom/RDFとしてパースする。
    static func fetchAndParse(url: URL, timeout: TimeInterval = 12) -> AnyPublisher<ParsedFeed, Error> {
        var request = URLRequest(url: url)
        request.timeoutInterval = timeout
        request.setValue(feedUserAgent, forHTTPHeaderField: "User-Agent")
        request.setValue(
            "application/rss+xml, application/atom+xml, application/xml, text/xml, */*",
            forHTTPHeaderField: "Accept"
        )
        
        return URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { data, response -> Data in
                guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
                    throw FeedFetchError.invalidResponse
                }
                return data
            }
            .tryMap { data -> ParsedFeed in
                guard looksLikeFeed(data: data) else { throw FeedFetchError.notAFeed }
                let parsed = FeedXMLParser().parse(data: data)
                guard !parsed.title.isEmpty || !parsed.items.isEmpty else { throw FeedFetchError.notAFeed }
                return parsed
            }
            .eraseToAnyPublisher()
    }
    
    // 指定したURLのHTMLを取得する。フィード発見(<link rel="alternate">)のために使用。
    static func fetchHTML(url: URL, timeout: TimeInterval = 12) -> AnyPublisher<(html: String, finalURL: URL), Error> {
        var request = URLRequest(url: url)
        request.timeoutInterval = timeout
        request.setValue(browserUserAgent, forHTTPHeaderField: "User-Agent")
        request.setValue("text/html,application/xhtml+xml", forHTTPHeaderField: "Accept")
        
        return URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { data, response -> (html: String, finalURL: URL) in
                guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
                    throw FeedFetchError.invalidResponse
                }
                guard let html = String(data: data, encoding: .utf8) ?? String(data: data, encoding: .isoLatin1) else {
                    throw FeedFetchError.decodingFailed
                }
                return (html, response.url ?? url)
            }
            .eraseToAnyPublisher()
    }
    
    static func looksLikeFeed(data: Data) -> Bool {
        let prefixData = data.prefix(4096)
        let prefixStr = String(data: prefixData, encoding: .utf8) ?? String(data: prefixData, encoding: .isoLatin1)
        guard let prefix = prefixStr else {
            return false
        }
        let lower = prefix.lowercased()
        guard lower.contains("<?xml") || lower.contains("<rss") || lower.contains("<feed") || lower.contains("rdf:rdf") else {
            return false
        }
        // HTMLエラーページ等の誤検出を避ける
        if lower.contains("<html") && !lower.contains("<rss") && !lower.contains("<feed") && !lower.contains("rdf:rdf") {
            return false
        }
        return true
    }
}
