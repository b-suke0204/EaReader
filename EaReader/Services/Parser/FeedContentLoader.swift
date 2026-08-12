//
//  FeedContentLoader.swift
//  EaReader
//
//  Created by Eisuke Nomoto on 2026/08/10.
//

import Foundation
import Combine

private struct FeedMetadata {
    var title: String
    var description: String?
    var link: URL?
}

enum FeedContentLoader {
    static func load(candidate: FeedCandidate) -> AnyPublisher<ParsedFeed, Error> {
        guard let provider = PaginatedFeedProviderRegistry.provider(for: candidate.feedURL) else {
            return FeedFetcher.fetchAndParse(url: candidate.feedURL)
        }
        return loadViaAPI(provider: provider, candidate: candidate)
    }
    
    // APIで記事一覧を取得しつつ、タイトル・説明はRSS側から補完する。
    // APIが0件だった場合は通常のRSS解析にフォールバックする。
    private static func loadViaAPI(
        provider: PaginatedFeedProvider.Type,
        candidate: FeedCandidate
    ) -> AnyPublisher<ParsedFeed, Error> {
        let items = provider.fetchItems(feedURL: candidate.feedURL)
        let fallbackTitle = provider.fallbackTitle(feedURL: candidate.feedURL)
        let metadata = FeedFetcher.fetchAndParse(url: candidate.feedURL)
            .map { parsed in FeedMetadata(title: parsed.title, description: parsed.description, link: parsed.link) }
            .catch { _ in Just(FeedMetadata(title: fallbackTitle, description: nil, link: candidate.siteURL)) }
            .eraseToAnyPublisher()
        
        return Publishers.Zip(items, metadata)
            .setFailureType(to: Error.self)
            .flatMap { apiItems, meta -> AnyPublisher<ParsedFeed, Error> in
                guard !apiItems.isEmpty else {
                    return FeedFetcher.fetchAndParse(url: candidate.feedURL)
                }
                let parsed = ParsedFeed(title: meta.title, link: meta.link, description: meta.description, items: apiItems)
                return Just(parsed).setFailureType(to: Error.self).eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }
}
