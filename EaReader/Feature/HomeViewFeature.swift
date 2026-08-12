//
//  HomeViewFeature.swift
//  EaReader
//
//  Created by Eisuke Nomoto on 2026/08/04.
//

import SwiftUI
import ComposableArchitecture

// HomeView用のFeature
@Reducer
struct HomeViewFeature {
    
    @ObservableState
    struct State: Equatable {
        @Presents var destination: Destination.State?  // 画面表示用
        var navPath = StackState<Path.State>()
        
        var deviceModel: DeviceModel<Device, UserFeed, Article>?
        var targetUserFeed: UserFeedModel<UserFeed, Article>?
        
        // ユーザーのFeed登録数を取得
        var registeredFeedCount: Int {
            self.deviceModel?.userFeeds.count ?? 0
        }
        
        // 最大記事数取得
        var articleMaxLength: Int {
            self.deviceModel?.device.maxLength ?? 100
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
        case destination(PresentationAction<Destination.Action>)
        case navPath(StackActionOf<Path>)
    }
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                let deviceModel: DeviceModel<Device, UserFeed, Article>
                // テストデータを注入する (XCUITestの場合は、このテストデータが使われる)
                if ProcessInfo.processInfo.arguments.contains("HomeViewUITest") {
                    deviceModel = DeviceMockModel().getMock()
                    return .send(.deviceModelLoaded(deviceModel))
                }
                deviceModel = DeviceMockModel().getMock()
                return .send(.deviceModelLoaded(deviceModel))
            case .deviceModelLoaded(let deviceModel):
                state.deviceModel = deviceModel
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
                
                state.navPath.removeLast()
                return .none
            case .destination(.presented(.searchViewFeature(.delegate(.updateItem(let feed))))):
                // SearchViewからdelegateで値を伝播
                state.deviceModel?.userFeeds.append(feed)
                return .none
            case .destination(.presented(.settingViewFeature(.delegate(.updateMaxLength(let num))))):
                // SettingViewからdelegateで値を伝播
                state.deviceModel?.device.maxLength = num
                return .none
            case .destination:
                return .none
            case .navPath:
                return .none
            }
        }
        .ifLet(\.$destination, action: \.destination)  // destinationを検知
        .forEach(\.navPath, action: \.navPath)
    }
}

extension HomeViewFeature.Destination.State: Equatable {}
extension HomeViewFeature.Path.State: Equatable {}
