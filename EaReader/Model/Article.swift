//
//  Article.swift
//  EaReader
//
//  Created by Eisuke Nomoto on 2026/08/04.
//

import Foundation

protocol ArticleType: Codable, Equatable {
    var id: UUID { get set }
    var feedId: Int { get set }
    var articleTitle: String { get set }
    var articleLink: URL? { get set }
    var summary: String? { get set }
    var guid: String? { get set }
    var isRead: Bool { get set }
    var isFavorite: Bool { get set }
    var isHidden: Bool { get set }
    var thumbnailURL: URL? { get set }
    var publishedAt: Date? { get set }
    var contentUpdatedAt: Date? { get set }
    var fetchedAt: Date { get set }
    var createdAt: Date { get set }
    var updatedAt: Date { get set }
}

struct Article: ArticleType {
    var id: UUID
    var feedId: Int
    var articleTitle: String
    var articleLink: URL?
    var summary: String?  // 追加
    var guid: String?
    var isRead: Bool
    var isFavorite: Bool
    var isHidden: Bool
    // <media:thumbnail>などフィード自体に含まれるサムネイル画像
    // nilの場合、表示側が記事ページのog:imageを遅延取得してフォールバックする
    var thumbnailURL: URL?  // 追加
    var publishedAt: Date?
    var contentUpdatedAt: Date?
    var fetchedAt: Date
    var createdAt: Date
    var updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id = "id"
        case feedId = "feed_id"
        case articleTitle = "article_title"
        case articleLink = "article_link"
        case summary = "summary"
        case guid = "guid"
        case isRead = "is_read"
        case isFavorite = "is_favorite"
        case isHidden = "is_hidden"
        case thumbnailURL = "thumbnail_url"
        case publishedAt = "published_at"
        case contentUpdatedAt = "content_updated_at"
        case fetchedAt = "fetched_at"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}


