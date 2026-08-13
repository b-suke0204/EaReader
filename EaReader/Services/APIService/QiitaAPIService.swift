//
//  QiitaAPIService.swift
//  EaReader
//
//  Created by Eisuke Nomoto on 2026/08/09.
//

import Foundation
import Combine

final class QiitaAPIService: PaginatedFeedProvider {
    // API応答用のModel
    private struct QiitaItem: Decodable {
        let id: String
        let title: String
        let url: URL
        let createdAt: String
        let body: String?
        
        enum CodingKeys: String, CodingKey {
            case id
            case title
            case url
            case body
            case createdAt = "created_at"
        }
        
        // Article.guid として利用
        var guid: String {
            id
        }
    }
    
    // Feed URLを作成
    
    // フィードURLが `qiita.com/tags/{tag}/feed` 形式ならタグ名を返す。
    static func tagName(fromFeedURL url: URL) -> String? {
        guard let host = url.host, host.contains("qiita.com") else {
            return nil
        }
        
        let components = url.pathComponents.filter { $0 != "/" }
        guard components.count >= 3,
              components[0] == "tags",
              components.last == "feed" else {
            return nil
        }
        
        return components[1].removingPercentEncoding ?? components[1]
    }
    
    // フィードURLが `qiita.com/{user}/feed` 形式ならユーザー名を返す。
    static func userName(fromFeedURL url: URL) -> String? {
        guard let host = url.host, host.contains("qiita.com") else {
            return nil
        }
        
        let components = url.pathComponents.filter { $0 != "/" }
        guard components.count == 2, components[1] == "feed" else {
            return nil
        }
        
        guard ![
            "tags",
            "organizations",
            "popular-items"
        ].contains(components[0]) else {
            return nil
        }
        
        return components[0].removingPercentEncoding
            ?? components[0]
    }
    
    // PaginatedFeedProviderの処理 ここから
    
    static func canHandle(feedURL: URL) -> Bool {
        tagName(fromFeedURL: feedURL) != nil || userName(fromFeedURL: feedURL) != nil
    }
    
    static func fetchItems(feedURL: URL) -> AnyPublisher<[Article], Never> {
        if let tag = tagName(fromFeedURL: feedURL) {
            return fetchTagItems(tag: tag)
        }
        if let user = userName(fromFeedURL: feedURL) {
            return fetchUserItems(user: user)
        }
        
        return Just([]).eraseToAnyPublisher()
    }
    
    static func fallbackTitle(feedURL: URL) -> String {
        if let tag = tagName(fromFeedURL: feedURL) {
            return "Qiita「\(tag)」タグの新着記事"
        }
        if let user = userName(fromFeedURL: feedURL) {
            return "Qiita: \(user) の投稿"
        }
        return "Qiita"
    }
    
    // PaginatedFeedProviderの処理 ここまで
    
    // APIアクセス
    
    static func fetchTagItems(tag: String, maxPages: Int = 3, perPage: Int = 20) -> AnyPublisher<[Article], Never> {
        fetchPages(
            endpoint: "https://qiita.com/api/v2/tags/\(encodePathComponent(tag))/items",
            maxPages: maxPages,
            perPage: perPage
        )
    }
    
    static func fetchUserItems(user: String, maxPages: Int = 3, perPage: Int = 20) -> AnyPublisher<[Article], Never> {
        fetchPages(
            endpoint: "https://qiita.com/api/v2/users/\(encodePathComponent(user))/items",
            maxPages: maxPages,
            perPage: perPage
        )
    }
    
    private static func fetchPages(endpoint: String, maxPages: Int, perPage: Int) -> AnyPublisher<[Article], Never> {
        let pagePublishers: [AnyPublisher<[QiitaItem], Never>] =
            (1...maxPages).map { page in
                fetchPage(
                    endpoint: endpoint,
                    page: page,
                    perPage: perPage
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
    
    private static func fetchPage(endpoint: String, page: Int, perPage: Int) -> AnyPublisher<[QiitaItem], Never> {
        guard var components = URLComponents(string: endpoint) else {
            return Just([]).eraseToAnyPublisher()
        }
        
        components.queryItems = [
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "per_page", value: String(perPage))
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
        .decode(type: [QiitaItem].self, decoder: JSONDecoder())
        .catch { _ in
            Just([])
        }
        .eraseToAnyPublisher()
    }
    
    // MARK: Articleに変換
    
    private static func makeArticle(from qiitaItem: QiitaItem) -> Article {
        let now = Date()
        let summary = qiitaItem.body.map {
            TextSanitizer.cleanSummary(String($0.prefix(500)))
        }
        
        return Article(
            id: UUID(),
            feedId: 0,
            articleTitle: TextSanitizer.cleanTitle(qiitaItem.title),
            articleLink: qiitaItem.url,
            summary: (summary?.isEmpty ?? true) ? nil : summary,
            guid: qiitaItem.guid,
            isRead: false,
            isFavorite: false,
            isHidden: false,
            publishedAt: RSSDateParser.parse(qiitaItem.createdAt) ?? now,
            contentUpdatedAt: now,
            fetchedAt: now,
            createdAt: now,
            updatedAt: now
        )
    }
    
    private static func encodePathComponent(_ value: String) -> String {
        value.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? value
    }
}
