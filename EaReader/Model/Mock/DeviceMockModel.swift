//
//  DeviceMockModel.swift
//  EaReader
//
//  Created by Eisuke Nomoto on 2026/08/04.
//

import Foundation

enum MockDataCount: Int {
    case one = 1
    case two = 2
    case three = 3
    case none = 0
}

// モックデータ
struct DeviceMockModel {
    
    func getMock(count: MockDataCount = .none) -> DeviceModel<Device, UserFeed, Article> {
        let deviceModel: DeviceModel = self.getMockData(count: count)
        return deviceModel
    }
    
    private func getMockData(count: MockDataCount) -> DeviceModel<Device, UserFeed, Article> {
        switch count {
        case .one:
            return self.getSingleMockData()
        case .two:
            return self.getDoubleMockData()
        case .three:
            return self.getTripleMockData()
        case .none:
            return self.getNoneMockData()
        }
    }
    
    // 26.08.04 B 一つだけのテストデータ取得
    private func getSingleMockData() -> DeviceModel<Device, UserFeed, Article> {
        self.getDeviceModel(feeds: [self.userFeedModel1])
    }
    
    // 2つの場合
    private func getDoubleMockData() -> DeviceModel<Device, UserFeed, Article> {
        self.getDeviceModel(feeds: [self.userFeedModel1, self.userFeedModel2])
    }
    
    // 3つの場合
    private func getTripleMockData() -> DeviceModel<Device, UserFeed, Article> {
        let userFeeds: [UserFeedModel] = [self.userFeedModel1, self.userFeedModel2, self.userFeedModel3]
        return self.getDeviceModel(feeds: userFeeds)
    }
    
    // ない場合
    private func getNoneMockData() -> DeviceModel<Device, UserFeed, Article> {
        self.getDeviceModel(feeds: [])
    }
    
    // 26.08.04 B DeviceModel取得
    private func getDeviceModel<U: UserFeedType, A: ArticleType>(
        feeds: [UserFeedModel<U, A>]
    ) -> DeviceModel<Device, U, A> {
        let device: Device = Device(
            id: 1,
            deviceId: "1",
            maxLength: 100,
            lastSeenAt: Date(),
            latestUpdatedAt: Date(),
            articleDisplayCount: 0,
            createdAt: Date(),
            updatedAt: Date()
        )
        let deviceModel: DeviceModel = DeviceModel(device: device, userFeeds: feeds)
        return deviceModel
    }
    
    // MARK: モックデータの個数分用意
    
    private var userFeedModel1: UserFeedModel = UserFeedModel<UserFeed, Article>(
        userFeed: DeviceMockModel.userFeed1,
        articles: [DeviceMockModel.article1]
    )
    
    private var userFeedModel2: UserFeedModel = UserFeedModel<UserFeed, Article>(
        userFeed: DeviceMockModel.userFeed2,
        articles: [DeviceMockModel.article1, DeviceMockModel.article2]
    )
    
    private var userFeedModel3: UserFeedModel = UserFeedModel<UserFeed, Article>(
        userFeed: DeviceMockModel.userFeed3,
        articles: [DeviceMockModel.article1, DeviceMockModel.article2, DeviceMockModel.article3]
    )
    
    static private var article1 = ArticleModel(article:
        Article(
            id: UUID(),
            feedId: 1,
            articleTitle: "わかるようでわからないssh接続について",
            articleLink: URL(string: "https://qiita.com/hrfm1623/items/91115760e4bd66f7995a")!,
            guid: "https://qiita.com/hrfm1623/items/91115760e4bd66f7995a",
            isRead: false,
            isFavorite: true,
            isHidden: false,
            publishedAt: Date(),
            contentUpdatedAt: Date(),
            fetchedAt: Date(),
            createdAt: Date(),
            updatedAt: Date()
        )
    )
    
    static private var article2 = ArticleModel(article:
        Article(
            id: UUID(),
            feedId: 1,
            articleTitle: "OS？カーネル開発？聞いたことありませんねその単語🤔【ITパスポート】",
            articleLink: URL(string: "https://qiita.com/prumnn/items/4da8a4aa027730db23e0")!,
            guid: "https://qiita.com/prumnn/items/4da8a4aa027730db23e0",
            isRead: true,
            isFavorite: true,
            isHidden: false,
            publishedAt: Date(),
            contentUpdatedAt: Date(),
            fetchedAt: Date(),
            createdAt: Date(),
            updatedAt: Date()
        ))
    
    static private var article3 = ArticleModel(article:
        Article(
            id: UUID(),
            feedId: 1,
            articleTitle: "ずぼらAI駆動開発、爆誕",
            articleLink: URL(
                string: "https://qiita.com/nobu34/items/224f55bc85b813930f61"
            )!,
            guid: "https://qiita.com/nobu34/items/224f55bc85b813930f61",
            isRead: false,
            isFavorite: false,
            isHidden: true,
            publishedAt: Date(),
            contentUpdatedAt: Date(),
            fetchedAt: Date(),
            createdAt: Date(),
            updatedAt: Date()
        )
    )
    
    static private var userFeed1: UserFeed = UserFeed(
        id: 1,
        deviceId: "1",
        feedTitle: "テストタイトル",
        link: URL(string: "https://example.com/feed")!,
        lastUpdatedAt: Date(),
        createdAt: Date(),
        updatedAt: Date(),
        deletedAt: Date()
    )
    
    static private var userFeed2: UserFeed = UserFeed(
        id: 2,
        deviceId: "2",
        feedTitle: "【SwiftUI】Listのスタイル",
        link: URL(string: "https://qiita.com/SNQ-2001/items/c5a839503fabf6fc8b35")!,
        lastUpdatedAt: Date(),
        createdAt: Date(),
        updatedAt: Date(),
        deletedAt: Date()
    )
    
    static private var userFeed3: UserFeed = UserFeed(
        id: 3,
        deviceId: "3",
        feedTitle: "富士山の山頂に登ってみたら日の出が予想以上に綺麗だった件",
        link: URL(string: "https://example.com/feed")!,
        lastUpdatedAt: Date(),
        createdAt: Date(),
        updatedAt: Date(),
        deletedAt: Date()
    )
}
