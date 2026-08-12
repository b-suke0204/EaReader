//
//  DevToAPIService.swift
//  EaReader
//
//  Created by Eisuke Nomoto on 2026/08/09.
//

import Foundation
import Combine

// Dev.toのAPIページネーションプロバイダを処理するクラス
enum DevToAPIService: PaginatedFeedProvider {
    // Dev.to記事の情報
    private struct DevArticle: Decodable {
        let id: Int
        let title: String
        let url: URL
        let canonicalURL: URL?
        let description: String?
        let publishedTimestamp: String
        
        enum CodingKeys: String, CodingKey {
            case id
            case title
            case url
            case canonicalURL = "canonical_url"
            case description
            case publishedTimestamp = "published_timestamp"
        }
        
        // Dev.toには、guidが登録されていないので、Article.guidとして登録するための値を用意
        var guid: String {
            (canonicalURL ?? url).absoluteString
        }
    }
    
    // `https://dev.to/feed/tag/{tag}` からタグ名を取り出す
    static func tagName(fromFeedURL url: URL) -> String? {
        guard let host = url.host, host == "dev.to" else {
            return nil
        }
        
        let components = url.pathComponents.filter { $0 != "/" }
        guard components.count >= 3,
              components[0] == "feed",
              components[1] == "tag" else {
            return nil
        }
        
        return components[2].removingPercentEncoding ?? components[2]
    }

    // PaginatedFeedProviderの処理 ここから
    
    static func canHandle(feedURL: URL) -> Bool {
        tagName(fromFeedURL: feedURL) != nil
    }

    static func fallbackTitle(feedURL: URL) -> String {
        guard let tag = tagName(fromFeedURL: feedURL) else {
            return "DEV Community"
        }
        return "DEV Community「\(tag)」タグの新着記事"
    }
    
    @MainActor
    static func fetchItems(feedURL: URL) -> AnyPublisher<[Article], Never> {
        guard let tag = tagName(fromFeedURL: feedURL) else {
            return Just([])
                .eraseToAnyPublisher()
        }
        let pagePublishers = (1...2).map { page in
            fetchPage(tag: tag, page: page)
        }
        
        return Publishers.MergeMany(pagePublishers)
            .collect()
            .map { pages in
                pages
                    .flatMap { $0 }
                    .map(makeFeedItem)
            }
            .eraseToAnyPublisher()
    }
    
    // PaginatedFeedProviderの処理 ここまで
    
    // Dev.toのAPIを叩いてページを解析
    private static func fetchPage(tag: String, page: Int, perPage: Int = 30) -> AnyPublisher<[DevArticle], Never> {
        guard var components = URLComponents(string: "https://dev.to/api/articles") else {
            return Just([]).eraseToAnyPublisher()
        }
        
        components.queryItems = [
            URLQueryItem(name: "tag", value: tag),
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "per_page", value: String(perPage))
        ]
        
        guard let url = components.url else {
            return Just([])
                .eraseToAnyPublisher()
        }
        
        var request = URLRequest(url: url)
        request.timeoutInterval = 10
        request.setValue(
            "SearchRSS/1.0 (iOS)",
            forHTTPHeaderField: "User-Agent"
        )
        
        return URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { data, response -> Data in
                guard let http = response as? HTTPURLResponse,
                      (200..<300).contains(http.statusCode) else {
                    throw FeedFetchError.invalidResponse
                }
                return data
            }
            .decode(type: [DevArticle].self, decoder: JSONDecoder())
            .catch { _ in
                Just([])
            }
            .eraseToAnyPublisher()
    }

    // Articleに変換
    private static func makeFeedItem(from article: DevArticle) -> Article {
        let now = Date()
        return Article(
            id: UUID(),
            feedId: 0,
            articleTitle: TextSanitizer.cleanTitle(article.title),
            articleLink: article.url,
            summary: article.description.map { TextSanitizer.cleanSummary($0) },
            guid: article.guid,
            isRead: false,
            isFavorite: false,
            isHidden: false,
            publishedAt: RSSDateParser.parse(article.publishedTimestamp) ?? now,
            contentUpdatedAt: now,
            fetchedAt: now,
            createdAt: now,
            updatedAt: now
        )
    }
}




