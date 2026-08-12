//
//  ArticleListFeature.swift
//  EaReader
//
//  Created by Eisuke Nomoto on 2026/08/09.
//

import SwiftUI
import ComposableArchitecture
import Combine

// 26.08.11 B 閲覧モード設定
enum BrowserMode {
    case all
    case favorites
    case archives
}

// 26.08.12 B 記事読み込み状態
enum ArticleListState {
    case loading
    case error(message: String)
    case empty
    case articles
}

// 記事一覧Feature作成
@Reducer
struct ArticleListFeature {
    
    @ObservableState
    struct  State: Equatable {
        @Presents var destination: Destination.State?
        
        var targetFeed: UserFeedModel<UserFeed, Article>?
        var targetURL: URL? = nil
        
        var browserMode: BrowserMode = .all
        
        // 読み込み時に使用
        var isLoading: Bool = false
        var isAccumulatingHistory: Bool = false  // UI側で履歴があったという表示をするために使用
        var feedDescription: String? = nil
        var errorMessage: String? = nil
        
        var emptyText: String {
            switch browserMode {
            case .all:
                return "記事が見つかりません"
            case .favorites:
                return "いいねした記事がありません"
            case .archives:
                return "アーカイブした記事がありません"
            }
        }
    }
    
    @Reducer
    enum Destination {
        case safariViewFeature(SafariWebFeature)  // Safari表示
    }
    
    enum Action {
        case onAppear(feed: UserFeedModel<UserFeed, Article>?)
        case loadArticlesResponse(Result<ParsedFeed, Error>)
        case itemTapped(articleModel: ArticleModel<Article>)
        case updateFavoriteStatus(articleModel: ArticleModel<Article>)
        case updateArchiveStatus(articleModel: ArticleModel<Article>)
        case checkFacorites  // いいね確認
        case checkArchives  // アーカイブ確認
        case destination(PresentationAction<Destination.Action>)
    }
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .onAppear(let feed):
                state.targetFeed = feed
                // ここで読み込み処理を入れる
                return loadArticles(&state)
            case .loadArticlesResponse(let result):
                switch result {
                case .success(let parsedFeed):
                    var models: [ArticleModel<Article>] = []
                    // DBにあるArticleデータが反映されていたら、それをマージさせる
                    let articles = parsedFeed.items
                    for article in articles {
//                        article.id = UUID()
                        // 空でない場合は、既存の記事かどうか判断して、違うものは追加
                        guard let _ = state.targetFeed?.articles.firstIndex(where: { target in
                            target.article.guid ?? "" == article.guid ?? ""
                        }) else {
                            // guidが存在しない場合は、追加
                            let newArticleModel = ArticleModel(article: article)
                            models.append(newArticleModel)
                            continue
                        }
                        print("記事ID: \(article.id)")
                    }
                    if !models.isEmpty {  // 新記事があれば、更新
                        state.targetFeed?.articles.append(contentsOf: models)
                    }
                    return .none
                case .failure(let error):
                    print("エラーが吐き出されました: \(error)")
                    state.errorMessage = error.localizedDescription
                    return .none
                }
            case .itemTapped(let articleModel):
                guard let articleLink = articleModel.article.articleLink else { return .none }
                state.targetURL = articleLink
                if !updateReadStatus(state: &state, articleModel: articleModel) { return .none }
                state.destination = .safariViewFeature(SafariWebFeature.State())
                return .none
            case .updateFavoriteStatus(let articleModel):
                if !updateFavoriteStatus(state: &state, articleModel: articleModel) { return .none }
                return .none
            case .updateArchiveStatus(let articleModel):
                if !updateArchiveStatus(state: &state, articleModel: articleModel) { return .none }
                return .none
            case .checkFacorites:
                if state.browserMode == .favorites {
                    state.browserMode = .all
                    return .none
                }
                state.browserMode = .favorites
                return .none
            case .checkArchives:
                if state.browserMode == .archives {
                    state.browserMode = .all
                    return .none
                }
                state.browserMode = .archives
                return .none
            case .destination:
                return .none
            }
        }
        .ifLet(\.$destination, action: \.destination)
    }
    
    // 既読状態更新 (true: 成功)
    private func updateReadStatus(state: inout State, articleModel: ArticleModel<Article>) -> Bool {
        guard let index = state.targetFeed?.articles.firstIndex(of: articleModel) else { return false }
        state.targetFeed?.articles[index].article.isRead = true
        return true
    }
    
    // いいね更新
    private func updateFavoriteStatus(state: inout State, articleModel: ArticleModel<Article>) -> Bool {
        guard let index = state.targetFeed?.articles.firstIndex(of: articleModel) else { return false }
        state.targetFeed?.articles[index].article.isFavorite.toggle()
        return true
    }
    
    // アーカイブ更新
    private func updateArchiveStatus(state: inout State, articleModel: ArticleModel<Article>) -> Bool {
        guard let index = state.targetFeed?.articles.firstIndex(of: articleModel) else { return false }
        state.targetFeed?.articles[index].article.isHidden.toggle()
        return true
    }
    
    private let articleCancellationID: String = "ArticleListFeature"
    
    func loadArticles(_ state: inout State) -> Effect<Action> {
        guard !state.isLoading else { return .none }
        state.isLoading = true
        state.errorMessage = nil
        
        guard
            let candidate = state.targetFeed?.feedCandidate,
            let feedURL = state.targetFeed?.userFeed.link
        else { return .none }
        let cachedHistory = FeedHistoryStore.shared.history(feedURL: feedURL)
        if !cachedHistory.isEmpty {
            state.isAccumulatingHistory = true  // 保存記事ありON
        }
        
        return .run { send in
            do {
                for try await parsed in await FeedContentLoader.load(candidate: candidate).values {
                    var merged = parsed
                    
                    merged.items = (cachedHistory + merged.items).sorted {
                        $0.publishedAt ?? .distantPast > $1.publishedAt ?? .distantPast
                    }
                    
                    await send(.loadArticlesResponse(.success(merged)))
                }
            } catch {
                await send(.loadArticlesResponse(.failure(error)))
            }
        }
        .cancellable(id: articleCancellationID, cancelInFlight: true)
    }
}

extension ArticleListFeature.Destination.State: Equatable {}




