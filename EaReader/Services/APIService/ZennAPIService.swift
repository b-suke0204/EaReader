//
//  ZennAPIService.swift
//  EaReader
//
//  Created by Eisuke Nomoto on 2026/08/09.
//

import Foundation
import Combine

final class ZennAPIService: PaginatedFeedProvider {
    // API応答用のModels
    private struct ArticlesResponse: Decodable {
        let articles: [ZennArticle]
    }
    
    // Zenn用の記事モデル
    private struct ZennArticle: Decodable {
        let title: String
        let path: String
        let publishedAt: String
        
        enum CodingKeys: String, CodingKey {
            case title
            case path
            case publishedAt = "published_at"
        }
        
        // Article.guid として利用
        var guid: String {
            path
        }
        
        // Article.articleLink として利用
        var articleURL: URL? {
            URL(string: "https://zenn.dev\(path)")
        }
    }
    
    // Feed用URL作成
    
    // `https://zenn.dev/topics/{topic}/feed` からトピック名を取り出す
    static func topicName(fromFeedURL url: URL) -> String? {
        guard let host = url.host, host.contains("zenn.dev") else {
            return nil
        }
        
        let components = url.pathComponents.filter { $0 != "/" }
        guard components.count >= 3,
              components[0] == "topics",
              components.last == "feed" else {
            return nil
        }
        
        return components[1].removingPercentEncoding ?? components[1]
    }
    
    // `https://zenn.dev/{user}/feed` からユーザー名を取り出す
    static func userName(fromFeedURL url: URL) -> String? {
        guard let host = url.host, host.contains("zenn.dev") else {
            return nil
        }
        
        let components = url.pathComponents.filter { $0 != "/" }
        guard components.count == 2, components[1] == "feed" else {
            return nil
        }
        guard components[0] != "topics" else {
            return nil
        }
        
        return components[0].removingPercentEncoding ?? components[0]
    }
    
    // PaginatedFeedProviderの処理 ここから
    
    static func canHandle(feedURL: URL) -> Bool {
        topicName(fromFeedURL: feedURL) != nil || userName(fromFeedURL: feedURL) != nil
    }
    
    static func fallbackTitle(feedURL: URL) -> String {
        if let topic = topicName(fromFeedURL: feedURL) {
            return "Zenn「\(topic)」トピックの新着記事"
        }
        if let user = userName(fromFeedURL: feedURL) {
            return "Zenn: \(user) の投稿"
        }
        return "Zenn"
    }
    
    static func fetchItems(feedURL: URL) -> AnyPublisher<[Article], Never> {
        
        if let topic = topicName(fromFeedURL: feedURL) {
            return fetchPages(
                queryName: "topicname",
                queryValue: topic
            )
        }
        
        if let user = userName(fromFeedURL: feedURL) {
            return fetchPages(
                queryName: "username",
                queryValue: user
            )
        }
        
        return Just([]).eraseToAnyPublisher()
    }
    
    // PaginatedFeedProviderの処理 ここまで
    
    // APIアクセス処理
    
    private static func fetchPages(
        queryName: String,
        queryValue: String,
        maxPages: Int = 2
    ) -> AnyPublisher<[Article], Never> {
        let pagePublishers: [AnyPublisher<[ZennArticle], Never>] = (1...maxPages).map { page in
            fetchPage(
                queryName: queryName,
                queryValue: queryValue,
                page: page
            )
        }
        
        return Publishers.MergeMany(pagePublishers)
            .collect()
            .map { pages in
                pages
                    .flatMap { $0 }
                    .map { article in
                        makeArticle(from: article)
                    }
            }
            .eraseToAnyPublisher()
    }
    
    private static func fetchPage(
        queryName: String,
        queryValue: String,
        page: Int
    ) -> AnyPublisher<[ZennArticle], Never> {
        guard var components = URLComponents(string: "https://zenn.dev/api/articles") else {
            return Just([]).eraseToAnyPublisher()
        }
        
        components.queryItems = [
            URLQueryItem(name: queryName, value: queryValue),
            URLQueryItem(name: "order", value: "latest"),
            URLQueryItem(name: "page", value: String(page))
        ]
        
        guard let url = components.url else {
            return Just([]).eraseToAnyPublisher()
        }
        
        var request = URLRequest(url: url)
        request.timeoutInterval = 10
        request.setValue("SearchRSS/1.0 (iOS)", forHTTPHeaderField: "User-Agent")
        
        return URLSession.shared.dataTaskPublisher(for: request)
        .tryMap { data, response -> Data in
            guard let http = response as? HTTPURLResponse,
                  (200..<300).contains(http.statusCode) else {
                throw FeedFetchError.invalidResponse
            }
            return data
        }
        .decode(type: ArticlesResponse.self, decoder: JSONDecoder())
        .map(\.articles)
        .catch { _ in
            Just([])
        }
        .eraseToAnyPublisher()
    }
    
    // MARK: Articleに変換
    
    private static func makeArticle(from article: ZennArticle) -> Article {
        let now = Date()
        return Article(
            id: UUID(),
            feedId: 0,
            articleTitle: TextSanitizer.cleanTitle(article.title),
            articleLink: article.articleURL,
            summary: nil,
            guid: article.guid,
            isRead: false,
            isFavorite: false,
            isHidden: false,
            publishedAt: RSSDateParser.parse(article.publishedAt) ?? now,
            contentUpdatedAt: now,
            fetchedAt: now,
            createdAt: now,
            updatedAt: now
        )
    }
}
