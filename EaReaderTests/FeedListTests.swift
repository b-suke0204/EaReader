//
//  FeedListTests.swift
//  EaReaderTests
//
//  Created by Eisuke Nomoto on 2026/08/09.
//

import Testing
@testable import EaReader
import ComposableArchitecture

struct FeedListTests {
    
    @Test("いいね数確認")
    func checkFavorites() async {
        let deviceMockModel = DeviceMockModel().getMock()
        guard let userFeed = deviceMockModel.userFeeds.last else { return }
        let favorites = userFeed.articles.filter({ $0.article.isFavorite }).count
        print("いいね数: \(favorites)")
        #expect(favorites != 0)
    }
    
    @Test("既読数確認")
    func checkReads() async {
        let deviceMockModel = DeviceMockModel().getMock()
        guard let userFeed = deviceMockModel.userFeeds.last else { return }
        let reads = userFeed.articles.filter({ $0.article.isRead }).count
        print("既読数: \(reads)")
        #expect(reads != 0)
    }
    
    @Test("アーカイブ数確認")
    func checkArchives() async {
        let deviceMockModel = DeviceMockModel().getMock()
        guard let userFeed = deviceMockModel.userFeeds.last else { return }
        let archives = userFeed.articles.filter({ $0.article.isHidden }).count
        print("アーカイブ数: \(archives)")
        #expect(archives != 0)
    }
    
}
