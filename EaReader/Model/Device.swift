//
//  Device.swift
//  EaReader
//
//  Created by Eisuke Nomoto on 2026/08/04.
//

import Foundation

protocol DeviceType: Codable, Equatable {
    var id: Int { get set }
    var deviceId: String { get set }
    var maxLength: Int { get set }
    var lastSeenAt: Date { get set }
    var latestUpdatedAt: Date { get set }
    var articleDisplayCount: Int { get set }
    var createdAt: Date { get set }
    var updatedAt: Date { get set }
}

struct Device: DeviceType {
    var id: Int
    var deviceId: String
    var maxLength: Int
    var lastSeenAt: Date
    var latestUpdatedAt: Date
    var articleDisplayCount: Int
    var createdAt: Date
    var updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id = "id"
        case deviceId = "device_id"
        case maxLength = "max_length"
        case lastSeenAt = "last_seen_at"
        case latestUpdatedAt = "latest_updated_at"
        case articleDisplayCount = "article_display_count"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}
