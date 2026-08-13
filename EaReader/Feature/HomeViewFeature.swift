//
//  HomeViewFeature.swift
//  EaReader
//
//  Created by Eisuke Nomoto on 2026/08/04.
//

import SwiftUI
import ComposableArchitecture

enum HomeViewLoadingState {
    case loading
    case noFeeds
    case feeds
}

// HomeView用のFeature
@Reducer
struct HomeViewFeature {
    
    @ObservableState
    struct State: Equatable {
        @Presents var destination: Destination.State?  // 画面表示用
        @Presents var alert: AlertState<Action.Alert>?
        var navPath = StackState<Path.State>()
        
        var deviceModel: DeviceModel<Device, UserFeed, Article>?
        var targetUserFeed: UserFeedModel<UserFeed, Article>?
        
        var isLoading: Bool = false  // 画面読み込みフラグ
        
        var loadingState: HomeViewLoadingState {
            if isLoading {
                return .loading
            }
            if registeredFeedCount.isZero() {
                return .noFeeds
            }
            return .feeds
        }
        
        // ユーザーのFeed登録数を取得
        var registeredFeedCount: Int {
            self.deviceModel?.userFeeds.count ?? 0
        }
        
        // 最大記事数取得
        var articleMaxLength: Int {
            self.deviceModel?.device.articleDisplayCount ?? 100
        }
    }
    
    @Reducer
    enum Path {
        case articleList(ArticleListFeature)
    }
    
    /*
     Destination.StateをEquatableに準拠させないとTestStoreが使えないが下のコードは、deprecatedになっている
     @Reducer(state: .equatable)
     下のようにextensionでDestination.StateをEquatable準拠にする
     extension HomeViewFeature.Destination.State: Equatable {}
    */
    @Reducer  // StateとActionが自動生成される
    enum Destination {
        case searchViewFeature(SearchViewFeature)
        case settingViewFeature(SettingViewFeature)
    }
    
    enum Action {
        case onAppear
        case deviceModelLoaded(DeviceModel<Device, UserFeed, Article>)
        case searchButtonTapped
        case settingButtonTapped
        case feedItemTapped(feed: UserFeedModel<UserFeed, Article>)
        case backButtonTapped(articles: [ArticleModel<Article>])  // ナビゲーションの戻るボタン押下処理
        case closeArticleListView  // 記事一覧画面を閉じる
        case fetchRegisteredFeeds  // ユーザーが登録したFeedを取得
        case fetchArticles(feeds: [UserFeedModel<UserFeed, Article>])  // 記事読み込み
        case storeArticles(articles: [Int: [ArticleModel<Article>]])
        case storeUserFeeds(feeds: [UserFeedModel<UserFeed, Article>])  // 取得したfeedsを入れる
        case alert(PresentationAction<Alert>)
        case destination(PresentationAction<Destination.Action>)
        case navPath(StackActionOf<Path>)
        
        public enum Alert: Equatable {
            case error(message: String)
        }
    }
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .onAppear:  // 読み込み中
//                FileUtility.deleteDeviceInfoJSONFile()  // テストで追加
                
                state.isLoading = true
                let deviceModel: DeviceModel<Device, UserFeed, Article>
                // テストデータを注入する (XCUITestの場合は、このテストデータが使われる)
                if ProcessInfo.processInfo.arguments.contains("HomeViewUITest") {
                    deviceModel = DeviceMockModel().getMock()
                    return .send(.deviceModelLoaded(deviceModel))
                }
                
                // サーバーにデータを保存する
                //                deviceModel = DeviceMockModel().getMock()
                
                // 新規保存の時に使う
                deviceModel = DeviceModel(device: makeDeviceModel(), userFeeds: [])
                
                return .run { send in
                    
                    if let deviceData: Device = try? await FileUtility.loadDeviceInfo() {
                        let deviceId = deviceData.deviceId
                        let urlString = "http://localhost/api/devices/\(deviceId)"
                        let result: Result<Device, SessionErrorType> = await APISession.fetch(from: urlString)
                        
                        switch result {
                        case .success(let device):
                            let deviceModel = DeviceModel<Device, UserFeed, Article>(device: device, userFeeds: [])
                            // デバイスIDは、端末で共通なので、アプリ全体で共有できるようにする
                            EaReaderConfig.deviceId = device.deviceId
                            print("\(device.deviceId)")
                            print("\(device.articleDisplayCount)")
                            await send(.deviceModelLoaded(deviceModel))
                            return
                        case .failure:
                            // ファイルがない場合は、新規デバイス登録処理へ移動
                            print("ファイルがありませんでした")
                        }
                    }
                    
                    if let jsonData = await APISession.jsonEncode(from: deviceModel.device) {
                        // デバイス情報を保存する
                        let urlString = "http://localhost/api/devices"
                        let result: Result<Device, SessionErrorType> = await APISession.connect(
                            from: urlString,
                            data: jsonData
                        )
                        
                        var fetchedDevice: Device?
                        switch result {
                        case .success(let device):
                            fetchedDevice = device
                            EaReaderConfig.deviceId = device.deviceId
                            print("デバイスが保存されました")
                        case .failure(let error):
                            print("デバイスの保存に失敗しました: \(error)")
                        }
                        
                        do {
                            try await FileUtility.saveDeviceInfo(of: jsonData)
                        } catch {
                            print("データの保存に失敗しました: \(error)")
                        }
                        
                        guard let device = fetchedDevice else { return }
                        let deviceModel: DeviceModel = DeviceModel<Device, UserFeed, Article>(
                            device: device,
                            userFeeds: []
                        )
                        await send(.deviceModelLoaded(deviceModel))
                    }
                }
            case .deviceModelLoaded(let deviceModel):
                state.deviceModel = deviceModel
                // deviceIdでfeedを検索するアクションに飛ばす
                return .send(.fetchRegisteredFeeds)
            case .fetchRegisteredFeeds:
                // 読み込む
                return .run { send in
                    let urlString = "http://localhost/api/userFeeds/\(EaReaderConfig.deviceId)"
                    let results: Result<[UserFeed], SessionErrorType> = await APISession.fetchAll(from: urlString)
                    
                    var feedModels: [UserFeedModel<UserFeed, Article>] = []
                    switch results {
                    case .success(let feeds):
                        for feed in feeds {
                            var userFeedModel = UserFeedModel<UserFeed, Article>(userFeed: feed, articles: [])
                            userFeedModel.feedCandidate = FeedCandidate(
                                feedURL: feed.link,
                                title: feed.feedTitle,
                                siteURL: feed.link,
                                summary: feed.summary,
                                iconURL: feed.iconURL,
                                source: FeedSource(rawValue: feed.source ?? "") ?? .domainGuess
                            )
                            feedModels.append(userFeedModel)
                        }
                    case .failure:
                        print("エラーが出ました")
                    }
                    await send(.storeUserFeeds(feeds: feedModels))
                }
            case .storeUserFeeds(let feeds):
                state.deviceModel?.userFeeds = feeds
                return .send(.fetchArticles(feeds: feeds))
            case .fetchArticles(let feedModels):
                // 記事読み込み
                return .run { send in
                    var fetchedArticles: [Int: [ArticleModel<Article>]] = [:]
                    
                    for feedModel in feedModels {
                        let feedId = await feedModel.userFeed.id
                        
                        let urlString = "http://localhost/api/articles/\(feedId)"
                        let result: Result<[Article], SessionErrorType> = await APISession.fetchAll(from: urlString)
                        
                        switch result {
                        case .success(let articles):
                            var articleModels: [ArticleModel<Article>] = []
                            for article in articles {
                                articleModels.append(ArticleModel(article: article))
                            }
                            fetchedArticles[feedId] = articleModels
                        case .failure(let message):
                            print("記事の取得に失敗しました\(message)")
                            fetchedArticles[feedId] = []
                        }
                    }
                    await send(.storeArticles(articles: fetchedArticles))
                }
            case .storeArticles(let fetchedArticles):
                for i in 0..<(state.deviceModel?.userFeeds.count ?? 0) {
                    guard let feedId = state.deviceModel?.userFeeds[i].userFeed.id else { continue }
                    if !(fetchedArticles[feedId]?.isEmpty ?? true) {
                        guard let articleModel = fetchedArticles[feedId] else { continue }
                        state.deviceModel?.userFeeds[i].articles = articleModel
                    }
                }
                state.isLoading = false
                return .none
            case .searchButtonTapped:
                state.destination = .searchViewFeature(SearchViewFeature.State())
                return .none
            case .settingButtonTapped:
                state.destination = .settingViewFeature(SettingViewFeature.State())
                return .none
            case .feedItemTapped(let feed):
                state.targetUserFeed = feed
                state.navPath.append(.articleList(ArticleListFeature.State()))
                return .none
            case .backButtonTapped(let articles):
                guard state.deviceModel != nil else { return .none }
                if let index = state.deviceModel?.userFeeds.firstIndex(where: {
                    $0.id == state.targetUserFeed?.id
                }) {
                    state.deviceModel?.userFeeds[index].articles = articles
                }
                
                return .run { send in
                    // ここで記事を更新もしくは、作成する処理を入れる
                    for model in articles {
                        let feedId = await model.article.feedId
                        let articleId = await model.article.id
                        let urlString = "http://localhost/api/articles/\(feedId)/\(articleId)"
                        
                        print("URL: \(urlString)")
                        
                        if let jsonData = await APISession.jsonEncode(from: model.article) {
                            let result: Result<Article, SessionErrorType> = await APISession.connect(
                                from: urlString,
                                data: jsonData,
                                httpMethod: .PUT
                            )
                            
                            switch result {
                            case .success:
                                print("記事保存に成功しました")
                                continue
                            case .failure:
                                print("記事保存に失敗しました")
                                continue
                            }
                        }
                    }
                    return await send(.closeArticleListView)
                }
            case .closeArticleListView:
                state.navPath.removeLast()  // 記事一覧を閉じる
                return .none
            case .destination(.presented(.searchViewFeature(.delegate(.updateItem(let feed))))):
                // SearchViewからdelegateで値を伝播
                state.deviceModel?.userFeeds.append(feed)
                return .none
            case .destination(.presented(.settingViewFeature(.delegate(.updateMaxLength(let device))))):
                // SettingViewからdelegateで値を伝播
                state.deviceModel?.device = device
                return .none
            case .alert(.presented(.error(let message))):
                state.alert = .init(title: {
                    TextState(message)
                })
                return .none
            case .destination:
                return .none
            case .navPath:
                return .none
            default:
                return .none
            }
        }
        .ifLet(\.$destination, action: \.destination)  // destinationを検知
        .forEach(\.navPath, action: \.navPath)
    }
    
    // 26.08.12 B デバイスモデルを生成
    private func makeDeviceModel() -> Device {
        let device = Device(
            id: 1,
            deviceId: UUID(),
            lastSeenAt: Date(),
            latestUpdatedAt: Date(),
            articleDisplayCount: 100,
            createdAt: Date(),
            updatedAt: Date()
        )
        return device
    }
}

extension HomeViewFeature.Destination.State: Equatable {}
extension HomeViewFeature.Path.State: Equatable {}
