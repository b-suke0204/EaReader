//
//  HomeView.swift
//  EaReader
//
//  Created by Eisuke Nomoto on 2026/08/04.
//

import SwiftUI
import ComposableArchitecture

// 26.08.04 B ホームビュー作成
struct HomeView: View {
    // sheetでBindingするために使用
    @Bindable var homeStore: StoreOf<HomeViewFeature> = Store(
        initialState: HomeViewFeature.State(),
        reducer: { HomeViewFeature() }
    )
    var body: some View {
        VStack {
            NavigationStack(path: $homeStore.scope(state: \.navPath, action: \.navPath)) {
                VStack {
                    EaReaderHeader(homeStore: homeStore, headerText: "EaReader")
                    // 26.08.13 B テストで表示
//                    Text("\(String(describing: homeStore.deviceModel?.device.deviceId))")
                    
                    switch homeStore.loadingState {
                    case .loading:
                        ProgressView("読み込み中")
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    case .noFeeds:
                        NoFeedView(homeStore: homeStore)
                    case .feeds:
                        FeedList(homeStore: homeStore)
                    case .error:
                        ContentUnavailableView("読み込みに失敗しました...", systemImage: "exclamationmark.icloud")
                    }
                }
            } destination: { store in
                switch store.case {
                case let .articleList(store):
                    FeedArticleList(homeStore: homeStore, articleListFeature: store)
                }
            }
        }
        .alert(store: homeStore.scope(state: \.$alert, action: \.alert))
        .alert(store: homeStore.scope(state: \.deleteAlert.$deleteAlert, action: \.deleteAlert.deleteAlert))
        .task {  // 初回起動時読み込み
            homeStore.send(.onAppear)
        }
        .sheet(
            item: $homeStore.scope(
                state: \.destination?.searchViewFeature,
                action: \.destination.searchViewFeature
            )
        ) { store in
            RSSSearchView(searchStore: store)
        }
        .sheet(
            item: $homeStore.scope(
                state: \.destination?.settingViewFeature,
                action: \.destination.settingViewFeature
            )
        ) { store in
            SettingView(homeStore: homeStore, settingStore: store)
        }
    }
    
    var feedCount: Int {
        homeStore.registeredFeedCount
    }
}

// 26.08.04 B Feed一覧ビュー
struct FeedList: View {
    @Bindable var homeStore: StoreOf<HomeViewFeature>
    var body: some View {
        List {
            ForEach(homeStore.deviceModel?.userFeeds ?? []) { item in
                FeedListItem(homeStore: homeStore, item: item)
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(action: {
                            guard let deviceModel = homeStore.deviceModel else { return }
                            homeStore.send(.deleteAlert(.showDeleteItemAlert(feed: item, device: deviceModel)))
                        }) {
                            Image(systemName: "trash")
                                .resizable()
                                .scaledToFit()
                        }
                        .tint(.red)
                    }
            }
        }
        .listStyle(.plain)
        .accessibilityIdentifier("FeedList")
    }
}

// 26.08.11 B Feed一覧項目
struct FeedListItem: View {
    let homeStore: StoreOf<HomeViewFeature>
    let item: UserFeedModel<UserFeed, Article>
    var body: some View {
        Button(action: {
            print("ボタンが押された: \(item.userFeed.feedTitle)")
            homeStore.send(.feedItemTapped(feed: item))
        }) {
            VStack(alignment: .leading) {
                FeedTitleAndBadges(item: item)
                Spacer()
                LatestFeedUpdateDate(item: item)
            }
        }
        .buttonStyle(.plain)
    }
}

// 26.08.11 B Feedのタイトルとバッジ
struct FeedTitleAndBadges: View {
    let item: UserFeedModel<UserFeed, Article>
    var body: some View {
        HStack {
            Text("\(item.userFeed.feedTitle)")
                .font(.headline)
                .lineLimit(1)
                .minimumScaleFactor(0.5)  // 50%まで縮小
            Spacer()
            Badges(item: item)
        }
    }
}

// 26.08.11 B Feed最終更新日
struct LatestFeedUpdateDate: View {
    let item: UserFeedModel<UserFeed, Article>
    var body: some View {
        HStack {
            Spacer()
            Text("最終更新日: \(DateUtility.getDateString(from: item.userFeed.updatedAt, formatType: .YMDLineHMSColon))")
                .font(.caption2)
                .lineLimit(1)
                .padding(.trailing, 5)
        }
        .padding(0)
    }
}

// 26.08.09 B バッジ群
struct Badges: View {
    let item: UserFeedModel<UserFeed, Article>
    private let listViewModel: FeedListViewModel = FeedListViewModel()
    var body: some View {
        if listViewModel.isShowingBadge(item, \.isHidden) {
            ArchiveBadge(number: listViewModel.getBadgeNumber(item, \.isHidden))
        }
        if listViewModel.isShowingBadge(item, \.isFavorite) {
            FavoriteBadge(number: listViewModel.getBadgeNumber(item, \.isFavorite))
        }
        if listViewModel.isShowingBadge(item, \.isRead, condition: !=) {
            NewBadge(number: listViewModel.getBadgeNumber(item, \.isRead, condition: !=))
        }
    }
}

struct FavoriteBadge: View {
    let number: Int
    var body: some View {
        IconView(number: number, iconName: "heart.fill", iconColor: Color.favorite)
    }
}

struct ArchiveBadge: View {
    let number: Int
    var body: some View {
        IconView(number: number, iconName: "eye", iconColor: Color.archive)
    }
}

struct NewBadge: View {
    let number: Int
    var body: some View {
        IconView(number: number, iconName: "New!!", iconColor: Color.noRead, isTextIcon: true)
    }
}
