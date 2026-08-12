//
//  FeedCandidateMockModel.swift
//  EaReader
//
//  Created by Eisuke Nomoto on 2026/08/08.
//

import Foundation

// 26.08.08 B Fed候補モックデータ作成クラス
struct FeedCandidateMockModel {
    
    // FeedCandidatesのモックデータ作成
    static func getMockData(count: MockDataCount = .none) -> [FeedCandidate] {
        var candidates: [FeedCandidate] = []
        for i in 0..<count.rawValue {
            guard var mockCandidate = self.getMockFeedCandidate() else { continue }
            mockCandidate.title = "\(mockCandidate.title): \(i)"
            candidates.append(mockCandidate)
        }
        return candidates
    }
    
    static private func getMockFeedCandidate() -> FeedCandidate? {
        guard let url = URL(string: "http://example.com") else { return nil }
        var candidate = FeedCandidate(feedURL: url, title: "テスト候補です", source: .direct)
        guard let siteURL = URL(string: "https://qiita.com") else { return nil }
        candidate.siteURL = siteURL
        return candidate
    }
    
}


