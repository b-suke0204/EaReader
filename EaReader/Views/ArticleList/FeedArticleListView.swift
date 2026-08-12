//
//  FeedArticleListView.swift
//  EaReader
//
//  Created by Eisuke Nomoto on 2026/08/09.
//

import SwiftUI
import ComposableArchitecture

// 26.08.08 B フィードで検索された記事一覧
struct FeedArticleList: View {
    @Bindable var homeStore: StoreOf<HomeViewFeature>
    @Bindable var articleListFeature: StoreOf<ArticleListFeature>
    var body: some View {
        VStack {
            Group {
                switch getArticleListState(of: articles) {
                case .loading:
                    ProgressView("読み込み中")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                case .error(let message):
                    ContentUnavailableView(
                        "読み込みエラー",
                        systemImage: "exclamationmark.triangle",
                        description: Text(message)
                    )
                case .empty:
                    ContentUnavailableView(articleListFeature.emptyText, systemImage: "tray")
                case .articles:
                    List {
                        ArticleDescription(articleListFeature: articleListFeature)
                        // アーカイブしていないもののみ表示する
                        ForEach(articles) { item in
                            ArticleListItem(item: item, articleListFeature: articleListFeature)
                        }
                    }
                    .listStyle(.plain)
                    
                }
            }
        }
        .navigationTitle(feedTitle)
        .navigationBarBackButtonHidden(true)
        .accessibilityIdentifier("SiteList")
        .toolbar {
            ToolbarImageButton(
                imageName: "chevron.left",
                btnColor: Color.black,
                placement: .topBarLeading,
                btnAction: {
                    guard let articles = articleListFeature.targetFeed?.articles else { return }
                    homeStore.send(.backButtonTapped(articles: articles))
                }
            )
            ToolbarImageButton(
                imageName: articleListFeature.browserMode == .favorites ? "heart.fill" : "heart",
                btnColor: Color.favorite,
                placement: .topBarTrailing,
                btnAction: {
                    print("いいね確認が押されました")
                    articleListFeature.send(.checkFacorites)
                }
            )
            ToolbarImageButton(
                imageName: articleListFeature.browserMode == .archives ? "eye.slash" : "eye",
                btnColor: Color.archive,
                placement: .topBarTrailing,
                btnAction: {
                    print("アーカイブが押されました")
                    articleListFeature.send(.checkArchives)
                }
            )
        }
        .fullScreenCover(
            item: $articleListFeature.scope(
                state: \.$destination.safariViewFeature, action: \.destination.safariViewFeature
            )
        ) { _ in
            if let targetURL = articleListFeature.targetURL {
                SafariWebView(url: targetURL)
            }
        }
        .task {
            // 記事をFeedから読み込む
            articleListFeature.send(.onAppear(feed: homeStore.targetUserFeed))
        }
    }
    
    // 26.08.12 B 記事の状態取得
    /*
     TCAは、StoreからStateの値を参照するために、/@dynamicMemberLookup/を使っているので、
     Stateから関数を参照できないのでView側に移動
    */
    func getArticleListState(of articles: [ArticleModel<Article>]) -> ArticleListState {
        if articleListFeature.isLoading && articleListFeature.targetFeed?.articles.isEmpty ?? true {
            return .loading
        }
        if let message = articleListFeature.errorMessage, articleListFeature.targetFeed?.articles.isEmpty ?? true {
            return .error(message: message)
        }
        if articles.isEmpty {
            return .empty
        }
        return .articles
    }
    
    // 表示する記事をフィルターする
    var articles: [ArticleModel<Article>] {
        let articleMaxLength = homeStore.articleMaxLength
        guard let articles = articleListFeature.targetFeed?.articles.prefix(articleMaxLength) else { return [] }
        switch articleListFeature.browserMode {
        case .all:
            return articles.filter { !$0.article.isHidden }
        case .favorites:
            return articles.filter { $0.article.isFavorite }
        case .archives:
            return articles.filter { $0.article.isHidden }
        }
    }
    
    var feedTitle: String {
        homeStore.targetUserFeed?.userFeed.feedTitle ?? ""
    }
}

// 26.08.12 B 記事一覧アイテム
struct ArticleListItem: View {
    let item: ArticleModel<Article>
    let articleListFeature: StoreOf<ArticleListFeature>
    var body: some View {
        Button(action: {
            print("ボタンが押された: \(item.article.articleTitle)")
            articleListFeature.send(.itemTapped(articleModel: item))
        }) {
            HStack(alignment: .top, spacing: 12) {
                ArticleListLeftItem(item: item, articleListFeature: articleListFeature)
                ArticleListRightItem(item: item)
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
        .disabled(item.article.articleLink == nil)
    }
}

// 記事のディスクリプション
struct ArticleDescription: View {
    let articleListFeature: StoreOf<ArticleListFeature>
    var body: some View {
        if let description = articleListFeature.feedDescription {
            Text(description)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .listRowSeparator(.hidden)
        }
    }
}

struct ArticleThumbnailView: View {
    let article: Article
    private let thumbnailSize: CGFloat = 68
    @State var thumbnailFeature: StoreOf<ArticleThumnailFeature> = Store(
        initialState: ArticleThumnailFeature.State(),
        reducer: {
            ArticleThumnailFeature()
        }
    )
    var body: some View {
        ZStack {
            if let url = thumbnailFeature.resolveURL {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFit()
                    case .failure:
                        ArticleThumbnailPlaceholder()
                            .overlay(ProgressView().scaleEffect(0.7))
                    default:
                        ArticleThumbnailPlaceholder()
                    }
                }
            } else if !thumbnailFeature.didFinishResolving {
                ArticleThumbnailPlaceholder()
                    .overlay(ProgressView().scaleEffect(0.7))
            } else {
                ArticleThumbnailPlaceholder()
            }
        }
        .frame(width: thumbnailSize, height: thumbnailSize)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .task(id: article.id) {
            thumbnailFeature.send(.onAppear(item: article))
        }
    }
}

struct ArticleThumbnailPlaceholder: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 10, style: .continuous)
            .fill(Color(.tertiarySystemFill))
            .overlay {
                Image(systemName: "photo")
                    .foregroundStyle(.secondary)
            }
    }
}
