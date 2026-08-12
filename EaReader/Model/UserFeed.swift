//
//  UserFeed.swift
//  EaReader
//
//  Created by Eisuke Nomoto on 2026/08/04.
//

import Foundation

protocol UserFeedType: Codable, Identifiable, Equatable {
    var id: Int { get set }
    var deviceId: String { get set }  // UUID String
    var feedTitle: String { get set }
    var link: URL { get set }
    var lastUpdatedAt: Date { get set }
    var createdAt: Date { get set }
    var updatedAt: Date { get set }
    var deletedAt: Date? { get set }
}

struct UserFeed: UserFeedType {
    var id: Int
    var deviceId: String  // UUID String
    var feedTitle: String
    var link: URL
    var lastUpdatedAt: Date
    var createdAt: Date
    var updatedAt: Date
    var deletedAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id = "id"
        case deviceId = "device_id"
        case feedTitle = "feed_title"
        case link = "link"
        case lastUpdatedAt = "last_updated_at"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case deletedAt = "deleted_at"
    }
}
